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

        guard let userId = SupabaseClient.shared.currentUserId else { return }

        do {
            let fetchedSessions: [Session] = try await SupabaseClient.shared
                .from(SupabaseClient.Table.sessions)
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
        guard let userId = SupabaseClient.shared.currentUserId else {
            throw SessionError.notAuthenticated
        }

        let session: Session = try await SupabaseClient.shared
            .from(SupabaseClient.Table.sessions)
            .insert([
                "professional_id": userId.uuidString,
                "attendant_id": attendantId?.uuidString as Any,
                "title": title as Any,
                "session_status": "recording"
            ])
            .select()
            .single()
            .execute()
            .value

        sessions.insert(session, at: 0)
        return session
    }

    // MARK: - Update Session

    func updateSession(_ sessionId: UUID, request: UpdateSessionRequest) async throws {
        var updateData: [String: Any] = [:]

        if let title = request.title {
            updateData["title"] = title
        }
        if let audioUrl = request.audioUrl {
            updateData["audio_url"] = audioUrl
        }
        if let audioChunks = request.audioChunks {
            updateData["audio_chunks"] = audioChunks
        }
        if let durationSeconds = request.durationSeconds {
            updateData["duration_seconds"] = durationSeconds
        }
        if let status = request.sessionStatus {
            updateData["session_status"] = status.rawValue
        }
        if let attendantId = request.attendantId {
            updateData["attendant_id"] = attendantId.uuidString
        }

        try await SupabaseClient.shared
            .from(SupabaseClient.Table.sessions)
            .update(updateData)
            .eq("id", value: sessionId)
            .execute()

        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            await loadSessions(forceRefresh: true)
        }
    }

    // MARK: - Delete Session

    func deleteSession(_ sessionId: UUID) async throws {
        try await SupabaseClient.shared
            .from(SupabaseClient.Table.sessions)
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

        let response: TranscribeResponse = try await SupabaseClient.shared.invoke(
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

        let response: GenerateResponse = try await SupabaseClient.shared.invoke(
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

        let response: SendResponse = try await SupabaseClient.shared.invoke(
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
