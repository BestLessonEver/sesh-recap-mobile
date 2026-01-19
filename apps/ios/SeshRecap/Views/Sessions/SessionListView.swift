import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SessionsViewModel
    @State private var searchText = ""

    var filteredSessions: [Session] {
        if searchText.isEmpty {
            return viewModel.sessions
        }
        return viewModel.sessions.filter { session in
            session.displayTitle.localizedCaseInsensitiveContains(searchText) ||
            session.attendant?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "waveform",
                        description: Text("Record your first session to get started")
                    )
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session, viewModel: viewModel)
                            } label: {
                                SessionListRow(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Sessions")
            .searchable(text: $searchText, prompt: "Search sessions")
            .refreshable {
                await viewModel.loadSessions(forceRefresh: true)
            }
            .task {
                await viewModel.loadSessions()
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let session = filteredSessions[index]
                try? await viewModel.deleteSession(session.id)
            }
        }
    }
}

struct SessionListRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            statusIcon
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let attendant = session.attendant {
                        Label(attendant.name, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                recapBadge
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch session.sessionStatus {
        case .recording:
            Image(systemName: "waveform")
                .foregroundStyle(.red)
        case .uploading:
            ProgressView()
        case .transcribing:
            Image(systemName: "text.bubble")
                .foregroundStyle(.orange)
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var recapBadge: some View {
        if let recap = session.recap {
            switch recap.status {
            case .sent:
                Text("Sent")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            case .draft:
                Text("Draft")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            case .failed:
                Text("Failed")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red.opacity(0.2))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    SessionListView(viewModel: SessionsViewModel())
}
