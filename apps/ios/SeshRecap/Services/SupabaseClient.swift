import Foundation
import Supabase

@MainActor
class Database {
    static let shared = Database()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
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

    func invoke(_ functionName: String, body: some Encodable) async throws {
        // Get auth token - throw if not available
        guard let session = try? await client.auth.session else {
            throw DatabaseError.notAuthenticated
        }
        client.functions.setAuth(token: session.accessToken)
        try await client.functions.invoke(functionName, options: .init(body: body))
    }

    func invoke<T: Decodable>(_ functionName: String, body: some Encodable) async throws -> T {
        // Get auth token - throw if not available
        guard let session = try? await client.auth.session else {
            throw DatabaseError.notAuthenticated
        }
        client.functions.setAuth(token: session.accessToken)
        return try await client.functions.invoke(functionName, options: .init(body: body))
    }
}

// MARK: - Errors
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
