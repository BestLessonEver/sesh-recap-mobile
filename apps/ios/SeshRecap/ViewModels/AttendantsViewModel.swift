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

        guard let userId = Database.shared.currentUserId else { return }

        do {
            let fetchedAttendants: [Attendant] = try await Database.shared
                .from(Database.Table.attendants)
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
        guard let userId = Database.shared.currentUserId else {
            throw AttendantError.notAuthenticated
        }

        let insertRequest = InsertAttendantRequest(
            professionalId: userId.uuidString,
            name: request.name,
            email: request.email,
            contactEmails: request.contactEmails,
            contactName: request.contactName,
            isSelfContact: request.isSelfContact,
            tags: request.tags,
            notes: request.notes
        )

        let attendant: Attendant = try await Database.shared
            .from(Database.Table.attendants)
            .insert(insertRequest)
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
        try await Database.shared
            .from(Database.Table.attendants)
            .update(request)
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
        try await Database.shared
            .from(Database.Table.attendants)
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
