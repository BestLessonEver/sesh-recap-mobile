import SwiftUI

struct AttendantDetailView: View {
    let attendant: Attendant
    @ObservedObject var viewModel: AttendantsViewModel
    @Environment(\.dismiss) private var dismiss

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

    init(attendant: Attendant, viewModel: AttendantsViewModel) {
        self.attendant = attendant
        self.viewModel = viewModel

        _name = State(initialValue: attendant.name)
        _email = State(initialValue: attendant.email ?? "")
        _contactName = State(initialValue: attendant.contactName ?? "")
        _contactEmails = State(initialValue: attendant.contactEmails?.joined(separator: ", ") ?? "")
        _isSelfContact = State(initialValue: attendant.isSelfContact)
        _notes = State(initialValue: attendant.notes ?? "")
        _tags = State(initialValue: attendant.tags?.joined(separator: ", ") ?? "")
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
                Toggle("Send recaps directly to attendant", isOn: $isSelfContact)
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
                if attendant.archived {
                    Button("Restore Attendant") {
                        restoreAttendant()
                    }
                } else {
                    Button("Archive Attendant", role: .destructive) {
                        archiveAttendant()
                    }
                }

                Button("Delete Permanently", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Edit Attendant")
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
        .confirmationDialog("Delete Attendant", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAttendant()
            }
        } message: {
            Text("This will permanently delete the attendant and cannot be undone.")
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var hasChanges: Bool {
        name != attendant.name ||
        email != (attendant.email ?? "") ||
        contactName != (attendant.contactName ?? "") ||
        contactEmails != (attendant.contactEmails?.joined(separator: ", ") ?? "") ||
        isSelfContact != attendant.isSelfContact ||
        notes != (attendant.notes ?? "") ||
        tags != (attendant.tags?.joined(separator: ", ") ?? "")
    }

    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let emailsArray = contactEmails.isEmpty ? nil :
                    contactEmails.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let tagsArray = tags.isEmpty ? nil :
                    tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                try await viewModel.updateAttendant(attendant.id, UpdateAttendantRequest(
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

    private func archiveAttendant() {
        Task {
            do {
                try await viewModel.archiveAttendant(attendant.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }

    private func restoreAttendant() {
        Task {
            do {
                try await viewModel.unarchiveAttendant(attendant.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }

    private func deleteAttendant() {
        Task {
            do {
                try await viewModel.deleteAttendant(attendant.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
