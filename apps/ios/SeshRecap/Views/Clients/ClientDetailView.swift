import SwiftUI

struct ClientDetailView: View {
    let client: Client
    @ObservedObject var viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var name: String
    @State private var email: String
    @State private var contactName: String
    @State private var contactEmails: String
    @State private var isSelfContact: Bool
    @State private var notes: String
    @State private var tags: String

    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var error: Error?

    init(client: Client, viewModel: ClientsViewModel) {
        self.client = client
        self.viewModel = viewModel

        _name = State(initialValue: client.name)
        _email = State(initialValue: client.email ?? "")
        _contactName = State(initialValue: client.contactName ?? "")
        _contactEmails = State(initialValue: client.contactEmails?.joined(separator: ", ") ?? "")
        _isSelfContact = State(initialValue: client.isSelfContact)
        _notes = State(initialValue: client.notes ?? "")
        _tags = State(initialValue: client.tags?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section {
                Toggle("Send recaps directly to client", isOn: $isSelfContact)
            } footer: {
                Text("When off, recaps will be sent to contact emails instead")
            }

            if !isSelfContact {
                Section("Parent/Guardian Contact") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Contact Emails (comma separated)", text: $contactEmails)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            }

            Section("Tags") {
                TextField("Tags (comma separated)", text: $tags)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }

            Section {
                if client.archived {
                    Button("Restore Client") {
                        restoreClient()
                    }
                } else {
                    Button("Archive Client", role: .destructive) {
                        archiveClient()
                    }
                }

                Button("Delete Permanently", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Edit Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(isSaving || !hasChanges)
            }
        }
        .disabled(isSaving)
        .confirmationDialog("Delete Client", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteClient()
            }
        } message: {
            Text("This will permanently delete the client and cannot be undone.")
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var hasChanges: Bool {
        name != client.name ||
        email != (client.email ?? "") ||
        contactName != (client.contactName ?? "") ||
        contactEmails != (client.contactEmails?.joined(separator: ", ") ?? "") ||
        isSelfContact != client.isSelfContact ||
        notes != (client.notes ?? "") ||
        tags != (client.tags?.joined(separator: ", ") ?? "")
    }

    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let emailsArray = contactEmails.isEmpty ? nil :
                    contactEmails.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let tagsArray = tags.isEmpty ? nil :
                    tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                try await viewModel.updateClient(client.id, UpdateClientRequest(
                    name: name,
                    email: email.isEmpty ? nil : email,
                    contactEmails: emailsArray,
                    contactName: contactName.isEmpty ? nil : contactName,
                    isSelfContact: isSelfContact,
                    tags: tagsArray,
                    notes: notes.isEmpty ? nil : notes
                ))
                dismiss()
            } catch {
                self.error = error
            }
            isSaving = false
        }
    }

    private func archiveClient() {
        Task {
            do {
                try await viewModel.archiveClient(client.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }

    private func restoreClient() {
        Task {
            do {
                try await viewModel.unarchiveClient(client.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }

    private func deleteClient() {
        Task {
            do {
                try await viewModel.deleteClient(client.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
