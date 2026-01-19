import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()

    private(set) var client: Supabase.SupabaseClient!

    private init() {}

    func configure() {
        client = Supabase.SupabaseClient(
            supabaseURL: Environment.supabaseURL,
            supabaseKey: Environment.supabaseAnonKey
        )
    }

    // MARK: - Database Helpers

    func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }

    // MARK: - Storage Helpers

    func storage(_ bucket: String) -> StorageFileApi {
        client.storage.from(bucket)
    }

    // MARK: - Auth Helpers

    var auth: AuthClient {
        client.auth
    }

    var currentUser: User? {
        try? client.auth.session?.user
    }

    var currentUserId: UUID? {
        currentUser?.id
    }

    // MARK: - Edge Functions

    func invoke<T: Decodable>(
        _ functionName: String,
        body: some Encodable
    ) async throws -> T {
        try await client.functions.invoke(
            functionName,
            options: FunctionInvokeOptions(body: body)
        )
    }

    func invoke(_ functionName: String, body: some Encodable) async throws {
        try await client.functions.invoke(
            functionName,
            options: FunctionInvokeOptions(body: body)
        )
    }
}

// MARK: - Table Names
extension SupabaseClient {
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
