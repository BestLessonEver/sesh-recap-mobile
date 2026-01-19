import SwiftUI

struct AddAttendantView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AttendantsViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var contactName = ""
    @State private var contactEmails = ""
    @State private var isSelfContact = true
    @State private var notes = ""
    @State private var tags = ""

    @State private var isSaving = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
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
                    Text("Turn off if recaps should go to a parent or guardian instead")
                }

                if !isSelfContact {
                    Section("Parent/Guardian Contact") {
                        TextField("Contact Name (e.g., 'Mom')", text: $contactName)
                        TextField("Contact Emails (comma separated)", text: $contactEmails)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Tags (optional)") {
                    TextField("e.g., beginner, piano, tuesday", text: $tags)
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add Attendant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAttendant()
                    }
                    .disabled(!isFormValid || isSaving)
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

    private var isFormValid: Bool {
        !name.isEmpty && (isSelfContact ? true : !contactEmails.isEmpty)
    }

    private func addAttendant() {
        isSaving = true
        Task {
            do {
                let emailsArray = contactEmails.isEmpty ? nil :
                    contactEmails.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let tagsArray = tags.isEmpty ? nil :
                    tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                _ = try await viewModel.createAttendant(CreateAttendantRequest(
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
}

#Preview {
    AddAttendantView(viewModel: AttendantsViewModel())
}
