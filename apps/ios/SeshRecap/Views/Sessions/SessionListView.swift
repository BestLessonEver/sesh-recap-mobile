import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SessionsViewModel
    @Binding var navigateToSessionId: UUID?
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()

    init(viewModel: SessionsViewModel, navigateToSessionId: Binding<UUID?> = .constant(nil)) {
        self.viewModel = viewModel
        self._navigateToSessionId = navigateToSessionId
    }

    var filteredSessions: [Session] {
        if searchText.isEmpty {
            return viewModel.sessions
        }
        return viewModel.sessions.filter { session in
            session.displayTitle.localizedCaseInsensitiveContains(searchText) ||
            session.client?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()

                if viewModel.sessions.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textTertiary)
                            .accessibilityHidden(true)
                        Text("No Sessions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textPrimary)
                        Text("Record your first session to get started")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                NavigationLink(value: session) {
                                    BrandSessionListRow(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search sessions")
            .refreshable {
                await viewModel.loadSessions(forceRefresh: true)
            }
            .task {
                await viewModel.loadSessions()
            }
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session, viewModel: viewModel)
            }
            .onChange(of: navigateToSessionId) { _, sessionId in
                if let sessionId = sessionId,
                   let session = viewModel.getSession(sessionId) {
                    navigationPath.append(session)
                    navigateToSessionId = nil
                }
            }
        }
    }
}

struct BrandSessionListRow: View {
    let session: Session

    var body: some View {
        BrandCard(padding: 16) {
            HStack(spacing: 12) {
                // Status Icon
                statusIcon
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.displayTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let client = session.client {
                            Label(client.name, systemImage: "person.fill")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Label(session.formattedDuration, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(session.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    recapBadge
                }
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.15))
                .frame(width: 40, height: 40)

            switch session.sessionStatus {
            case .recording:
                Image(systemName: "waveform")
                    .foregroundStyle(statusColor)
            case .uploading:
                ProgressView()
                    .tint(statusColor)
            case .transcribing:
                Image(systemName: "text.bubble")
                    .foregroundStyle(statusColor)
            case .ready:
                Image(systemName: "checkmark")
                    .foregroundStyle(statusColor)
            case .error:
                Image(systemName: "exclamationmark")
                    .foregroundStyle(statusColor)
            }
        }
        .accessibilityLabel(statusAccessibilityLabel)
    }

    private var statusAccessibilityLabel: String {
        switch session.sessionStatus {
        case .recording: return "Recording in progress"
        case .uploading: return "Uploading"
        case .transcribing: return "Transcribing"
        case .ready: return "Ready"
        case .error: return "Error"
        }
    }

    private var statusColor: Color {
        switch session.sessionStatus {
        case .recording: return .error
        case .uploading, .transcribing: return .warning
        case .ready: return .success
        case .error: return .error
        }
    }

    @ViewBuilder
    private var recapBadge: some View {
        if let recap = session.recap {
            let status: StatusPill.Status = {
                switch recap.status {
                case .sent: return .sent
                case .draft: return .draft
                case .failed: return .error
                }
            }()
            StatusPill(status: status)
        }
    }
}

#Preview {
    SessionListView(viewModel: SessionsViewModel(), navigateToSessionId: .constant(nil))
}
