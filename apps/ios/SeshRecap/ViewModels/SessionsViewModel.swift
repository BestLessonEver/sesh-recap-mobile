import Foundation

@MainActor
class SessionsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var hasLoadedOnce = false

    // MARK: - Load Sessions

    func loadSessions(forceRefresh: Bool = false) async {
        if hasLoadedOnce && !forceRefresh && !sessions.isEmpty {
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let userId = Database.shared.currentUserId else { return }

        do {
            let fetchedSessions: [Session] = try await Database.shared
                .from(Database.Table.sessions)
                .select("""
                    *,
                    attendant:attendants(*),
                    recap:recaps(*)
                """)
                .eq("professional_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            sessions = fetchedSessions
            hasLoadedOnce = true
        } catch {
            self.error = error
        }
    }

    // MARK: - Create Session

    func createSession(attendantId: UUID?, title: String?) async throws -> Session {
        guard let userId = Database.shared.currentUserId else {
            throw SessionError.notAuthenticated
        }

        // Ensure professional row exists (handles case where DB trigger failed)
        try await ensureProfessionalExists(userId: userId)

        // professionals.id = auth.users.id (same UUID)
        let insertRequest = InsertSessionRequest(
            professionalId: userId.uuidString,
            attendantId: attendantId?.uuidString,
            title: title,
            sessionStatus: "recording"
        )

        let session: Session = try await Database.shared
            .from(Database.Table.sessions)
            .insert(insertRequest)
            .select()
            .single()
            .execute()
            .value

        sessions.insert(session, at: 0)
        return session
    }

    // MARK: - Ensure Professional Exists

    private func ensureProfessionalExists(userId: UUID) async throws {
        let professionals: [Professional] = try await Database.shared
            .from(Database.Table.professionals)
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        if professionals.isEmpty {
            let user = Database.shared.currentUser
            let request = InsertProfessionalRequest(
                id: userId.uuidString,
                name: user?.userMetadata["name"] as? String ?? user?.email ?? "User",
                email: user?.email ?? ""
            )
            try await Database.shared
                .from(Database.Table.professionals)
                .insert(request)
                .execute()
        }
    }

    // MARK: - Update Session

    func updateSession(_ sessionId: UUID, request: UpdateSessionRequest) async throws {
        try await Database.shared
            .from(Database.Table.sessions)
            .update(request)
            .eq("id", value: sessionId)
            .execute()

        if sessions.contains(where: { $0.id == sessionId }) {
            await loadSessions(forceRefresh: true)
        }
    }

    // MARK: - Delete Session

    func deleteSession(_ sessionId: UUID) async throws {
        try await Database.shared
            .from(Database.Table.sessions)
            .delete()
            .eq("id", value: sessionId)
            .execute()

        sessions.removeAll { $0.id == sessionId }
    }

    // MARK: - Transcribe

    func transcribeSession(_ sessionId: UUID) async throws {
        struct TranscribeRequest: Codable {
            let sessionId: String
        }

        struct TranscribeResponse: Codable {
            let success: Bool
            let transcript: String?
        }

        let response: TranscribeResponse = try await Database.shared.invoke(
            "transcribe",
            body: TranscribeRequest(sessionId: sessionId.uuidString)
        )

        if response.success {
            await loadSessions(forceRefresh: true)
        }
    }

    // MARK: - Generate Recap

    func generateRecap(_ sessionId: UUID) async throws {
        struct GenerateRequest: Codable {
            let sessionId: String
        }

        struct GenerateResponse: Codable {
            let success: Bool
            let recap: Recap?
        }

        let response: GenerateResponse = try await Database.shared.invoke(
            "generate-recap",
            body: GenerateRequest(sessionId: sessionId.uuidString)
        )

        if response.success {
            await loadSessions(forceRefresh: true)
        }
    }

    // MARK: - Send Recap

    func sendRecap(_ sessionId: UUID) async throws {
        struct SendRequest: Codable {
            let sessionId: String
        }

        struct SendResponse: Codable {
            let success: Bool
            let sentTo: [String]?
        }

        let response: SendResponse = try await Database.shared.invoke(
            "send-recap",
            body: SendRequest(sessionId: sessionId.uuidString)
        )

        if response.success {
            await loadSessions(forceRefresh: true)
        }
    }

    // MARK: - Get Session

    func getSession(_ id: UUID) -> Session? {
        sessions.first { $0.id == id }
    }
}

enum SessionError: LocalizedError {
    case notAuthenticated
    case sessionNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to create sessions"
        case .sessionNotFound:
            return "Session not found"
        }
    }
}
