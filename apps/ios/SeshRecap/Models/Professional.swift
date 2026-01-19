import Foundation

struct Professional: Codable, Identifiable, Equatable {
    let id: UUID
    var organizationId: UUID?
    var name: String
    let email: String
    var role: Role
    let createdAt: Date
    var updatedAt: Date

    enum Role: String, Codable, CaseIterable {
        case owner
        case admin
        case member
    }

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case name
        case email
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InsertProfessionalRequest: Codable {
    let id: String
    let name: String
    let email: String
}

struct Organization: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var recapPrompt: String?
    var subscriptionStatus: SubscriptionStatus
    var maxProfessionals: Int
    var trialEndsAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum SubscriptionStatus: String, Codable {
        case trialing
        case active
        case pastDue = "past_due"
        case canceled
        case expired
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case recapPrompt = "recap_prompt"
        case subscriptionStatus = "subscription_status"
        case maxProfessionals = "max_professionals"
        case trialEndsAt = "trial_ends_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isActive: Bool {
        subscriptionStatus == .active || subscriptionStatus == .trialing
    }
}
