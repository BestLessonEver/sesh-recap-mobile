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
        // Ensure auth token is set before invoking (workaround for SDK auth header issue)
        if let accessToken = try? await client.auth.session.accessToken {
            client.functions.setAuth(token: accessToken)
        }
        try await client.functions.invoke(functionName, options: .init(body: body))
    }

    func invoke<T: Decodable>(_ functionName: String, body: some Encodable) async throws -> T {
        // Ensure auth token is set before invoking (workaround for SDK auth header issue)
        if let accessToken = try? await client.auth.session.accessToken {
            client.functions.setAuth(token: accessToken)
        }
        return try await client.functions.invoke(functionName, options: .init(body: body))
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
