import SwiftUI

struct SessionDetailView: View {
    let session: Session
    @ObservedObject var viewModel: SessionsViewModel

    @State private var showEditRecap = false
    @State private var isGeneratingRecap = false
    @State private var isSendingRecap = false
    @State private var error: Error?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Session Info Card
                sessionInfoCard

                // Transcript Section
                if let transcript = session.transcriptText {
                    transcriptSection(transcript)
                } else if session.sessionStatus == .transcribing {
                    transcribingSection
                }

                // Recap Section
                if session.canGenerateRecap {
                    recapSection
                }
            }
            .padding()
        }
        .navigationTitle(session.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditRecap) {
            if let recap = session.recap {
                RecapEditorView(recap: recap, session: session, viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        statusIndicator
                        Text(session.sessionStatus.rawValue.capitalized)
                            .font(.subheadline)
                    }
                }
            }

            if let attendant = session.attendant {
                Divider()
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                    Text(attendant.name)
                    Spacer()
                    if let email = attendant.displayEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(session.createdAt, style: .date)
                Text("at")
                    .foregroundStyle(.secondary)
                Text(session.createdAt, style: .time)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        switch session.sessionStatus {
        case .ready: return .green
        case .transcribing: return .orange
        case .error: return .red
        default: return .gray
        }
    }

    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.headline)

            Text(transcript)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var transcribingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Transcribing audio...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var recapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recap")
                    .font(.headline)
                Spacer()
                if let recap = session.recap {
                    Menu {
                        Button {
                            showEditRecap = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        if recap.canSend {
                            Button {
                                sendRecap()
                            } label: {
                                Label("Send", systemImage: "paperplane")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }

            if let recap = session.recap {
                recapCard(recap)
            } else {
                generateRecapButton
            }
        }
    }

    private func recapCard(_ recap: Recap) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recap.subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                recapStatusBadge(recap)
            }

            Text(recap.bodyText)
                .font(.body)
                .lineLimit(5)

            if recap.canSend {
                Button {
                    sendRecap()
                } label: {
                    Label("Send Recap", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSendingRecap)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func recapStatusBadge(_ recap: Recap) -> some View {
        switch recap.status {
        case .sent:
            Text("Sent")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .draft:
            Text("Draft")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .failed:
            Text("Failed")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }

    private var generateRecapButton: some View {
        Button {
            generateRecap()
        } label: {
            HStack {
                if isGeneratingRecap {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGeneratingRecap ? "Generating..." : "Generate AI Recap")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isGeneratingRecap)
    }

    private func generateRecap() {
        isGeneratingRecap = true
        Task {
            do {
                try await viewModel.generateRecap(session.id)
            } catch {
                self.error = error
            }
            isGeneratingRecap = false
        }
    }

    private func sendRecap() {
        isSendingRecap = true
        Task {
            do {
                try await viewModel.sendRecap(session.id)
            } catch {
                self.error = error
            }
            isSendingRecap = false
        }
    }
}
