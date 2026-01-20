import Foundation

struct Client: Codable, Identifiable, Equatable {
    let id: UUID
    let professionalId: UUID
    var organizationId: UUID?
    var name: String
    var email: String?
    var contactEmails: [String]?
    var contactName: String?
    var isSelfContact: Bool
    var tags: [String]?
    var notes: String?
    var archived: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case professionalId = "professional_id"
        case organizationId = "organization_id"
        case name
        case email
        case contactEmails = "contact_emails"
        case contactName = "contact_name"
        case isSelfContact = "is_self_contact"
        case tags
        case notes
        case archived
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayEmail: String? {
        if isSelfContact {
            return email
        }
        return contactEmails?.first
    }

    var allEmails: [String] {
        var emails: [String] = []
        if isSelfContact, let email = email {
            emails.append(email)
        }
        if let contactEmails = contactEmails {
            emails.append(contentsOf: contactEmails)
        }
        return emails
    }
}

struct CreateClientRequest {
    let name: String
    let email: String?
    let contactEmails: [String]?
    let contactName: String?
    let isSelfContact: Bool
    let tags: [String]?
    let notes: String?
}

struct InsertClientRequest: Codable {
    let professionalId: String
    let name: String
    let email: String?
    let contactEmails: [String]?
    let contactName: String?
    let isSelfContact: Bool
    let tags: [String]?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case professionalId = "professional_id"
        case name
        case email
        case contactEmails = "contact_emails"
        case contactName = "contact_name"
        case isSelfContact = "is_self_contact"
        case tags
        case notes
    }
}

struct UpdateClientRequest: Codable {
    var name: String?
    var email: String?
    var contactEmails: [String]?
    var contactName: String?
    var isSelfContact: Bool?
    var tags: [String]?
    var notes: String?
    var archived: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case email
        case contactEmails = "contact_emails"
        case contactName = "contact_name"
        case isSelfContact = "is_self_contact"
        case tags
        case notes
        case archived
    }
}
