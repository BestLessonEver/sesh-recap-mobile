import SwiftUI

struct SessionDetailView: View {
    let session: Session
    @ObservedObject var viewModel: SessionsViewModel

    @State private var showEditRecap = false
    @State private var isGeneratingRecap = false
    @State private var isSendingRecap = false
    @State private var error: Error?

    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()

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
        }
        .navigationTitle(session.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        BrandCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        Text(session.formattedDuration)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        HStack(spacing: 4) {
                            statusIndicator
                            Text(session.sessionStatus.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                }

                if let attendant = session.attendant {
                    Rectangle()
                        .fill(Color.border)
                        .frame(height: 1)

                    HStack {
                        GradientAvatar(name: attendant.name, size: 32)
                        Text(attendant.name)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if let email = attendant.displayEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.border)
                    .frame(height: 1)

                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.textSecondary)
                    Text(session.createdAt, style: .date)
                        .foregroundStyle(Color.textPrimary)
                    Text("at")
                        .foregroundStyle(Color.textSecondary)
                    Text(session.createdAt, style: .time)
                        .foregroundStyle(Color.textPrimary)
                }
                .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch session.sessionStatus {
        case .ready: return .success
        case .transcribing: return .warning
        case .error: return .error
        default: return .textTertiary
        }
    }

    private func transcriptSection(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            BrandCard {
                Text(transcript)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var transcribingSection: some View {
        BrandCard {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.brandPink)
                Text("Transcribing audio...")
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private var recapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recap")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
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
                            .foregroundStyle(Color.brandPink)
                    }
                    .accessibilityLabel("Recap options")
                    .accessibilityHint("Edit or send this recap")
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
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(recap.subject)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    recapStatusBadge(recap)
                }

                Text(recap.bodyText)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(5)

                if recap.canSend {
                    Button {
                        sendRecap()
                    } label: {
                        HStack {
                            if isSendingRecap {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isSendingRecap ? "Sending..." : "Send Recap")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.brandGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isSendingRecap)
                }
            }
        }
    }

    @ViewBuilder
    private func recapStatusBadge(_ recap: Recap) -> some View {
        let status: StatusPill.Status = {
            switch recap.status {
            case .sent: return .sent
            case .draft: return .draft
            case .failed: return .error
            }
        }()
        StatusPill(status: status)
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
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient.brandGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
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
