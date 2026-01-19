import Foundation

struct Session: Codable, Identifiable, Equatable {
    let id: UUID
    let professionalId: UUID
    var organizationId: UUID?
    var attendantId: UUID?
    var title: String?
    var audioUrl: String?
    var audioChunks: [String]?
    var durationSeconds: Int
    var transcriptText: String?
    var sessionStatus: SessionStatus
    let createdAt: Date
    var updatedAt: Date

    // Joined data
    var attendant: Attendant?
    var recap: Recap?

    enum SessionStatus: String, Codable {
        case recording
        case uploading
        case transcribing
        case ready
        case error
    }

    enum CodingKeys: String, CodingKey {
        case id
        case professionalId = "professional_id"
        case organizationId = "organization_id"
        case attendantId = "attendant_id"
        case title
        case audioUrl = "audio_url"
        case audioChunks = "audio_chunks"
        case durationSeconds = "duration_seconds"
        case transcriptText = "transcript_text"
        case sessionStatus = "session_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case attendant
        case recap
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var displayTitle: String {
        title ?? "Session on \(createdAt.formatted(date: .abbreviated, time: .shortened))"
    }

    var hasRecap: Bool {
        recap != nil
    }

    var canGenerateRecap: Bool {
        sessionStatus == .ready && transcriptText != nil
    }
}

struct CreateSessionRequest: Codable {
    let attendantId: UUID?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case attendantId = "attendant_id"
        case title
    }
}

struct UpdateSessionRequest: Codable {
    var attendantId: UUID?
    var title: String?
    var audioUrl: String?
    var audioChunks: [String]?
    var durationSeconds: Int?
    var sessionStatus: Session.SessionStatus?

    enum CodingKeys: String, CodingKey {
        case attendantId = "attendant_id"
        case title
        case audioUrl = "audio_url"
        case audioChunks = "audio_chunks"
        case durationSeconds = "duration_seconds"
        case sessionStatus = "session_status"
    }
}
