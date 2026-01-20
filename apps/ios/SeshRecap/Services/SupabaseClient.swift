import Foundation
import Supabase

@MainActor
class Database {
    static let shared = Database()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Auth Helpers

    var auth: AuthClient {
        client.auth
    }

    var currentUser: User? {
        client.auth.currentUser
    }

    var currentUserId: UUID? {
        currentUser?.id
    }

    // MARK: - Database

    func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }

    // MARK: - Storage

    func storage(_ bucket: String) -> StorageFileApi {
        client.storage.from(bucket)
    }

    // MARK: - Functions

    /// Refreshes the auth session, falling back to current session if refresh fails
    private func getValidSession(for functionName: String) async throws -> Auth.Session {
        do {
            let session = try await client.auth.refreshSession()
            print("Refreshed session for \(functionName)")
            return session
        } catch {
            print("Refresh failed, trying current session: \(error)")
            do {
                return try await client.auth.session
            } catch {
                print("Auth session error: \(error)")
                throw DatabaseError.notAuthenticated
            }
        }
    }

    func invoke(_ functionName: String, body: some Encodable) async throws {
        let authSession = try await getValidSession(for: functionName)

        print("Invoking \(functionName) with token: \(authSession.accessToken.prefix(20))...")

        // Use BOTH setAuth AND explicit header to ensure token is sent
        client.functions.setAuth(token: authSession.accessToken)

        // Pass Authorization header explicitly as well
        try await client.functions.invoke(
            functionName,
            options: FunctionInvokeOptions(
                headers: ["Authorization": "Bearer \(authSession.accessToken)"],
                body: body
            )
        )
    }

    func invoke<T: Decodable>(_ functionName: String, body: some Encodable) async throws -> T {
        let authSession = try await getValidSession(for: functionName)

        // Use raw URLSession to bypass SDK and ensure headers are sent correctly
        let url = AppConfig.supabaseURL.appendingPathComponent("functions/v1/\(functionName)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authSession.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(body)

        print("Direct HTTP call to: \(url)")
        print("Auth header: Bearer \(authSession.accessToken.prefix(30))...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DatabaseError.notAuthenticated
        }

        print("Response status: \(httpResponse.statusCode)")
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "no body"
            print("Error response: \(errorBody)")

            // Try to parse the error message from JSON
            var errorMessage = "An error occurred"
            if let errorJson = try? JSONDecoder().decode(FunctionErrorResponse.self, from: data) {
                errorMessage = errorJson.error
            }

            throw FunctionError.failed(message: errorMessage, code: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Errors

struct FunctionErrorResponse: Codable {
    let error: String
    let errorType: String?
    let success: Bool?
}

enum FunctionError: LocalizedError {
    case failed(message: String, code: Int)

    var errorDescription: String? {
        switch self {
        case .failed(let message, _):
            return message
        }
    }
}

enum DatabaseError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in again."
        }
    }
}

// MARK: - Table Names
extension Database {
    enum Table {
        static let organizations = "organizations"
        static let professionals = "professionals"
        static let attendants = "attendants"
        static let sessions = "sessions"
        static let recaps = "recaps"
        static let subscriptions = "subscriptions"
        static let invitations = "invitations"
        static let deviceTokens = "device_tokens"
    }
}
