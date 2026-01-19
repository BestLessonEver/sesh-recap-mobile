import Foundation
import Supabase
import AuthenticationServices

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var session: Session?
    @Published private(set) var user: User?
    @Published private(set) var isAuthenticated = false

    private var authStateListener: Task<Void, Never>?

    private init() {
        startAuthStateListener()
    }

    deinit {
        authStateListener?.cancel()
    }

    private func startAuthStateListener() {
        authStateListener = Task {
            for await state in SupabaseClient.shared.auth.authStateChanges {
                await MainActor.run {
                    self.session = state.session
                    self.user = state.session?.user
                    self.isAuthenticated = state.session != nil
                }
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        let session = try await SupabaseClient.shared.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        await MainActor.run {
            self.session = session
            self.user = session.user
            self.isAuthenticated = true
        }

        // Update name if provided
        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            if !name.isEmpty {
                try await updateProfile(name: name)
            }
        }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String, name: String) async throws {
        let session = try await SupabaseClient.shared.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )

        await MainActor.run {
            self.session = session.session
            self.user = session.session?.user
            self.isAuthenticated = session.session != nil
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await SupabaseClient.shared.auth.signIn(
            email: email,
            password: password
        )

        await MainActor.run {
            self.session = session
            self.user = session.user
            self.isAuthenticated = true
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await SupabaseClient.shared.auth.signOut()

        await MainActor.run {
            self.session = nil
            self.user = nil
            self.isAuthenticated = false
        }
    }

    // MARK: - Profile

    func updateProfile(name: String) async throws {
        guard let userId = user?.id else {
            throw AuthError.notAuthenticated
        }

        try await SupabaseClient.shared
            .from(SupabaseClient.Table.professionals)
            .update(["name": name])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Session

    func refreshSession() async throws {
        let session = try await SupabaseClient.shared.auth.refreshSession()
        await MainActor.run {
            self.session = session
            self.user = session.user
        }
    }

    func getSession() async throws -> Session? {
        try await SupabaseClient.shared.auth.session
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case notAuthenticated
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .notAuthenticated:
            return "You are not signed in"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        }
    }
}
