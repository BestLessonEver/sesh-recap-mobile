import Foundation
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var currentProfessional: Professional?

    private let authService = AuthService.shared

    // MARK: - Auth State

    func checkAuth() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let session = try await authService.getSession() {
                isAuthenticated = true
                await loadCurrentProfessional()

                // Configure RevenueCat
                SubscriptionService.shared.configure(userId: session.user.id.uuidString)
            }
        } catch {
            isAuthenticated = false
        }
    }

    private func loadCurrentProfessional() async {
        guard let userId = SupabaseClient.shared.currentUserId else { return }

        do {
            let professional: Professional = try await SupabaseClient.shared
                .from(SupabaseClient.Table.professionals)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            currentProfessional = professional
        } catch {
            print("Failed to load professional: \(error)")
        }
    }

    // MARK: - Apple Sign In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                error = AuthError.invalidCredentials
                return
            }

            do {
                try await authService.signInWithApple(credential: appleCredential)
                await checkAuth()
            } catch {
                self.error = error
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                self.error = error
            }
        }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await authService.signUp(email: email, password: password, name: name)
            await checkAuth()
        } catch {
            self.error = error
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            await checkAuth()
        } catch {
            self.error = error
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
            isAuthenticated = false
            currentProfessional = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Profile

    func updateName(_ name: String) async {
        do {
            try await authService.updateProfile(name: name)
            currentProfessional?.name = name
        } catch {
            self.error = error
        }
    }
}
