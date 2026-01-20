import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name: String = ""
    @State private var isSaving = false
    @State private var showSuccess = false

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $name)

                HStack {
                    Text("Email")
                    Spacer()
                    Text(authViewModel.currentProfessional?.email ?? "")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    saveProfile()
                } label: {
                    HStack {
                        Text("Save Changes")
                        Spacer()
                        if isSaving {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSaving || name == authViewModel.currentProfessional?.name)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = authViewModel.currentProfessional?.name ?? ""
        }
        .overlay {
            if showSuccess {
                VStack {
                    Spacer()
                    Text("Profile saved")
                        .foregroundStyle(Color.textPrimary)
                        .padding()
                        .background(Color.bgCard)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .padding(.bottom, 50)
                        .accessibilityAddTraits(.isStaticText)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: showSuccess) { _, newValue in
            if newValue {
                UIAccessibility.post(notification: .announcement, argument: "Profile saved successfully")
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        Task {
            await authViewModel.updateName(name)
            isSaving = false
            withAnimation {
                showSuccess = true
            }
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSuccess = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
