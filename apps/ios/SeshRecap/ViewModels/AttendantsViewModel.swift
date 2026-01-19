import Foundation

@MainActor
class AttendantsViewModel: ObservableObject {
    @Published var attendants: [Attendant] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var hasLoadedOnce = false

    var activeAttendants: [Attendant] {
        attendants.filter { !$0.archived }
    }

    var archivedAttendants: [Attendant] {
        attendants.filter { $0.archived }
    }

    // MARK: - Load Attendants

    func loadAttendants(forceRefresh: Bool = false) async {
        if hasLoadedOnce && !forceRefresh && !attendants.isEmpty {
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let userId = SupabaseClient.shared.currentUserId else { return }

        do {
            let fetchedAttendants: [Attendant] = try await SupabaseClient.shared
                .from(SupabaseClient.Table.attendants)
                .select()
                .eq("professional_id", value: userId)
                .order("name")
                .execute()
                .value

            attendants = fetchedAttendants
            hasLoadedOnce = true
        } catch {
            self.error = error
        }
    }

    // MARK: - Create Attendant

    func createAttendant(_ request: CreateAttendantRequest) async throws -> Attendant {
        guard let userId = SupabaseClient.shared.currentUserId else {
            throw AttendantError.notAuthenticated
        }

        var data: [String: Any] = [
            "professional_id": userId.uuidString,
            "name": request.name,
            "is_self_contact": request.isSelfContact
        ]

        if let email = request.email {
            data["email"] = email
        }
        if let contactEmails = request.contactEmails {
            data["contact_emails"] = contactEmails
        }
        if let contactName = request.contactName {
            data["contact_name"] = contactName
        }
        if let tags = request.tags {
            data["tags"] = tags
        }
        if let notes = request.notes {
            data["notes"] = notes
        }

        let attendant: Attendant = try await SupabaseClient.shared
            .from(SupabaseClient.Table.attendants)
            .insert(data)
            .select()
            .single()
            .execute()
            .value

        attendants.append(attendant)
        attendants.sort { $0.name < $1.name }

        return attendant
    }

    // MARK: - Update Attendant

    func updateAttendant(_ id: UUID, _ request: UpdateAttendantRequest) async throws {
        var updateData: [String: Any] = [:]

        if let name = request.name {
            updateData["name"] = name
        }
        if let email = request.email {
            updateData["email"] = email
        }
        if let contactEmails = request.contactEmails {
            updateData["contact_emails"] = contactEmails
        }
        if let contactName = request.contactName {
            updateData["contact_name"] = contactName
        }
        if let isSelfContact = request.isSelfContact {
            updateData["is_self_contact"] = isSelfContact
        }
        if let tags = request.tags {
            updateData["tags"] = tags
        }
        if let notes = request.notes {
            updateData["notes"] = notes
        }
        if let archived = request.archived {
            updateData["archived"] = archived
        }

        try await SupabaseClient.shared
            .from(SupabaseClient.Table.attendants)
            .update(updateData)
            .eq("id", value: id)
            .execute()

        await loadAttendants(forceRefresh: true)
    }

    // MARK: - Archive Attendant

    func archiveAttendant(_ id: UUID) async throws {
        try await updateAttendant(id, UpdateAttendantRequest(archived: true))
    }

    func unarchiveAttendant(_ id: UUID) async throws {
        try await updateAttendant(id, UpdateAttendantRequest(archived: false))
    }

    // MARK: - Delete Attendant

    func deleteAttendant(_ id: UUID) async throws {
        try await SupabaseClient.shared
            .from(SupabaseClient.Table.attendants)
            .delete()
            .eq("id", value: id)
            .execute()

        attendants.removeAll { $0.id == id }
    }

    // MARK: - Get Attendant

    func getAttendant(_ id: UUID) -> Attendant? {
        attendants.first { $0.id == id }
    }
}

enum AttendantError: LocalizedError {
    case notAuthenticated
    case attendantNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage attendants"
        case .attendantNotFound:
            return "Attendant not found"
        }
    }
}
