import SwiftUI

struct RecapEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    let recap: Recap
    let session: Session
    @ObservedObject var viewModel: SessionsViewModel

    @State private var subject: String
    @State private var bodyText: String
    @State private var isSaving = false
    @State private var error: Error?

    init(recap: Recap, session: Session, viewModel: SessionsViewModel) {
        self.recap = recap
        self.session = session
        self.viewModel = viewModel
        _subject = State(initialValue: recap.subject)
        _bodyText = State(initialValue: recap.bodyText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject") {
                    TextField("Subject", text: $subject)
                }

                Section("Body") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 300)
                }

                if let client = session.client {
                    Section("Recipients") {
                        ForEach(client.allEmails, id: \.self) { email in
                            Label(email, systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle("Edit Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecap()
                    }
                    .disabled(isSaving || !hasChanges)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
        }
    }

    private var hasChanges: Bool {
        subject != recap.subject || bodyText != recap.bodyText
    }

    private func saveRecap() {
        isSaving = true
        Task {
            do {
                try await Database.shared
                    .from(Database.Table.recaps)
                    .update([
                        "subject": subject,
                        "body_text": bodyText
                    ])
                    .eq("id", value: recap.id)
                    .execute()

                await viewModel.loadSessions(forceRefresh: true)
                dismiss()
            } catch {
                self.error = error
            }
            isSaving = false
        }
    }
}
