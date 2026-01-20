import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmailAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.bgPrimary
                    .ignoresSafeArea()

                // Gradient blobs
                GradientBlob(color: .brandPink, size: 200)
                    .offset(x: -100, y: -200)
                GradientBlob(color: .brandGold, size: 150)
                    .offset(x: 150, y: 100)

                VStack(spacing: 32) {
                    Spacer()

                    // Logo and Title
                    VStack(spacing: 20) {
                        // Gradient icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient.brandGradientVertical)
                                .frame(width: 100, height: 100)

                            Image(systemName: "waveform")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(Color.bgPrimary)
                        }
                        .accessibilityHidden(true)

                        VStack(spacing: 8) {
                            BrandText(text: "Sesh.Rec", font: .largeTitle)

                            Text("Record sessions, generate AI recaps,\nand send summaries to attendees.")
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()

                    // Auth Buttons
                    VStack(spacing: 16) {
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task {
                                await authViewModel.handleAppleSignIn(result: result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            showEmailAuth = true
                        } label: {
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.bgCard)
                                .foregroundStyle(Color.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Terms
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $showEmailAuth) {
                SignInView()
            }
            .overlay {
                if authViewModel.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel("Signing in")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(authViewModel.isLoading ? .updatesFrequently : [])
            .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
                Button("OK") {
                    authViewModel.error = nil
                }
            } message: {
                Text(authViewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
