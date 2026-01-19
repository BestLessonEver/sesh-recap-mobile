import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)

                Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            // Form
            VStack(spacing: 16) {
                if isSignUp {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            // Submit Button
            Button {
                Task {
                    if isSignUp {
                        await authViewModel.signUp(email: email, password: password, name: name)
                    } else {
                        await authViewModel.signIn(email: email, password: password)
                    }
                }
            } label: {
                Text(isSignUp ? "Create Account" : "Sign In")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!isFormValid)
            .padding(.horizontal)

            // Toggle
            Button {
                withAnimation {
                    isSignUp.toggle()
                }
            } label: {
                if isSignUp {
                    Text("Already have an account? ") +
                    Text("Sign In").fontWeight(.semibold)
                } else {
                    Text("Don't have an account? ") +
                    Text("Sign Up").fontWeight(.semibold)
                }
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .navigationBarBackButtonHidden(authViewModel.isLoading)
        .overlay {
            if authViewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") {
                authViewModel.error = nil
            }
        } message: {
            Text(authViewModel.error?.localizedDescription ?? "An error occurred")
        }
    }

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8
        let nameValid = !isSignUp || name.count >= 2
        return emailValid && passwordValid && nameValid
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
