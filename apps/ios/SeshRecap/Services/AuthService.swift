import Foundation
import Supabase
import Auth
import AuthenticationServices

// Type alias to avoid conflict with our Session model
typealias AuthSession = Auth.Session

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var session: AuthSession?
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
            for await (event, session) in Database.shared.auth.authStateChanges {
                self.session = session
                self.user = session?.user
                self.isAuthenticated = session != nil
            }
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        let session = try await Database.shared.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: tokenString
            )
        )

        self.session = session
        self.user = session.user
        self.isAuthenticated = true

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
        let response = try await Database.shared.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )

        switch response {
        case .session(let session):
            self.session = session
            self.user = session.user
            self.isAuthenticated = true
        case .user:
            // Email confirmation required
            break
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await Database.shared.auth.signIn(
            email: email,
            password: password
        )

        self.session = session
        self.user = session.user
        self.isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await Database.shared.auth.signOut()

        self.session = nil
        self.user = nil
        self.isAuthenticated = false
    }

    // MARK: - Profile

    func updateProfile(name: String) async throws {
        guard let userId = user?.id else {
            throw AuthError.notAuthenticated
        }

        try await Database.shared
            .from(Database.Table.professionals)
            .update(["name": name])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Session

    func refreshSession() async throws {
        let session = try await Database.shared.auth.refreshSession()
        self.session = session
        self.user = session.user
    }

    func getSession() async throws -> AuthSession? {
        try await Database.shared.auth.session
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
