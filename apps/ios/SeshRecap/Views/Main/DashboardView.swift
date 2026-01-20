import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.bgPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        HeroSection {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome back,")
                                        .foregroundStyle(Color.textSecondary)
                                    Text(authViewModel.currentProfessional?.name ?? "Professional")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.textPrimary)
                                }
                                Spacer()
                                GradientAvatar(
                                    name: authViewModel.currentProfessional?.name ?? "U",
                                    size: 48
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Stats Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            BrandStatCard(
                                title: "Total Sessions",
                                value: "\(viewModel.stats.thisWeekSessions)",
                                icon: "clock.fill",
                                iconColor: .brandPink
                            )

                            BrandStatCard(
                                title: "Clients",
                                value: "\(viewModel.stats.totalClients)",
                                icon: "person.2.fill",
                                iconColor: .brandGold
                            )

                            BrandStatCard(
                                title: "Time Recorded",
                                value: viewModel.stats.formattedThisWeekTime,
                                icon: "waveform",
                                iconColor: .success
                            )

                            BrandStatCard(
                                title: "Recaps Sent",
                                value: "\(viewModel.stats.sentRecaps)",
                                icon: "envelope.fill",
                                iconColor: .brandPink
                            )
                        }
                        .padding(.horizontal)

                        // Recent Sessions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Sessions")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                NavigationLink {
                                    SessionListView(viewModel: viewModel.sessionsViewModel)
                                } label: {
                                    Text("View all")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.brandPink)
                                }
                            }
                            .padding(.horizontal)

                            if viewModel.recentSessions.isEmpty {
                                BrandCard {
                                    VStack(spacing: 12) {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 40))
                                            .foregroundStyle(Color.textTertiary)
                                            .accessibilityHidden(true)
                                        Text("No Sessions Yet")
                                            .font(.headline)
                                            .foregroundStyle(Color.textPrimary)
                                        Text("Tap the record button to start your first session")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                }
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.recentSessions) { session in
                                        NavigationLink {
                                            SessionDetailView(session: session, viewModel: viewModel.sessionsViewModel)
                                        } label: {
                                            BrandSessionRow(session: session)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80) // Space for tab bar
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
}

// MARK: - Brand Stat Card

struct BrandStatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(iconColor)
                    }
                    .accessibilityHidden(true)
                    Spacer()
                }

                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Brand Session Row

struct BrandSessionRow: View {
    let session: Session

    var body: some View {
        BrandCard(padding: 12) {
            HStack(spacing: 12) {
                // Avatar
                if let client = session.client {
                    GradientAvatar(name: client.name, size: 40)
                } else {
                    GradientAvatar(name: "?", size: 40)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let client = session.client {
                            Text(client.name)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Text(session.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 4) {
                    sessionStatusPill
                    Text(session.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionStatusPill: some View {
        let status: StatusPill.Status = {
            switch session.sessionStatus {
            case .ready:
                return session.recap?.status == .sent ? .sent : .ready
            case .transcribing:
                return .pending
            case .error:
                return .error
            default:
                return .draft
            }
        }()
        StatusPill(status: status)
    }
}

#Preview {
    DashboardView(
        viewModel: DashboardViewModel(
            sessionsViewModel: SessionsViewModel(),
            clientsViewModel: ClientsViewModel()
        )
    )
    .environmentObject(AuthViewModel())
}
