import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .foregroundStyle(.secondary)
                            Text(authViewModel.currentProfessional?.name ?? "Professional")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "This Week",
                            value: "\(viewModel.stats.thisWeekSessions)",
                            subtitle: "sessions",
                            icon: "calendar",
                            color: .blue
                        )

                        StatCard(
                            title: "Time Recorded",
                            value: viewModel.stats.formattedThisWeekTime,
                            subtitle: "this week",
                            icon: "clock.fill",
                            color: .green
                        )

                        StatCard(
                            title: "Attendants",
                            value: "\(viewModel.stats.totalAttendants)",
                            subtitle: "active",
                            icon: "person.2.fill",
                            color: .purple
                        )

                        StatCard(
                            title: "Recaps Sent",
                            value: "\(viewModel.stats.sentRecaps)",
                            subtitle: "total",
                            icon: "envelope.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Recent Sessions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Sessions")
                                .font(.headline)
                            Spacer()
                            NavigationLink("See All") {
                                SessionListView(viewModel: viewModel.sessionsViewModel)
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)

                        if viewModel.recentSessions.isEmpty {
                            ContentUnavailableView(
                                "No Sessions Yet",
                                systemImage: "waveform",
                                description: Text("Tap the record button to start your first session")
                            )
                            .frame(height: 200)
                        } else {
                            ForEach(viewModel.recentSessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session, viewModel: viewModel.sessionsViewModel)
                                } label: {
                                    SessionRow(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            // Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let attendant = session.attendant {
                        Text(attendant.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(session.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var statusColor: Color {
        switch session.sessionStatus {
        case .ready:
            return session.recap?.status == .sent ? .green : .blue
        case .transcribing:
            return .orange
        case .error:
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    DashboardView(
        viewModel: DashboardViewModel(
            sessionsViewModel: SessionsViewModel(),
            attendantsViewModel: AttendantsViewModel()
        )
    )
    .environmentObject(AuthViewModel())
}
