import Foundation

struct Recap: Codable, Identifiable, Equatable {
    let id: UUID
    let sessionId: UUID
    var organizationId: UUID?
    var subject: String
    var bodyText: String
    var status: RecapStatus
    var sentAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum RecapStatus: String, Codable {
        case draft
        case sent
        case failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case organizationId = "organization_id"
        case subject
        case bodyText = "body_text"
        case status
        case sentAt = "sent_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isSent: Bool {
        status == .sent
    }

    var canSend: Bool {
        status == .draft
    }
}

struct UpdateRecapRequest: Codable {
    var subject: String?
    var bodyText: String?

    enum CodingKeys: String, CodingKey {
        case subject
        case bodyText = "body_text"
    }
}
