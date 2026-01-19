import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        ZStack {
            // Background
            Color.bgPrimary
                .ignoresSafeArea()

            // Gradient blobs
            GradientBlob(color: .brandPink, size: 150)
                .offset(x: 120, y: -300)
            GradientBlob(color: .brandGold, size: 100)
                .offset(x: -100, y: 200)

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)

                    Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 32)

                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        BrandTextField(
                            placeholder: "Name",
                            text: $name,
                            contentType: .name,
                            capitalization: .words
                        )
                    }

                    BrandTextField(
                        placeholder: "Email",
                        text: $email,
                        contentType: .emailAddress,
                        keyboardType: .emailAddress,
                        capitalization: .never
                    )

                    BrandSecureField(
                        placeholder: "Password",
                        text: $password,
                        contentType: isSignUp ? .newPassword : .password
                    )
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
                        .background(
                            isFormValid
                                ? AnyShapeStyle(LinearGradient.brandGradient)
                                : AnyShapeStyle(Color.textTertiary)
                        )
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
                        Text("Sign In").fontWeight(.semibold).foregroundColor(.brandPink)
                    } else {
                        Text("Don't have an account? ") +
                        Text("Sign Up").fontWeight(.semibold).foregroundColor(.brandPink)
                    }
                }
                .foregroundStyle(Color.textSecondary)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(authViewModel.isLoading)
        .overlay {
            if authViewModel.isLoading {
                Color.black.opacity(0.5)
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

// MARK: - Brand Text Field

struct BrandTextField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        TextField(placeholder, text: $text)
            .textContentType(contentType)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(capitalization)
            .padding()
            .background(Color.bgCard)
            .foregroundStyle(Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

struct BrandSecureField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType?

    var body: some View {
        SecureField(placeholder, text: $text)
            .textContentType(contentType)
            .padding()
            .background(Color.bgCard)
            .foregroundStyle(Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
