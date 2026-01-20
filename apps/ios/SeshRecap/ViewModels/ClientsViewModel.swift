import Foundation

@MainActor
class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var hasLoadedOnce = false

    var activeClients: [Client] {
        clients.filter { !$0.archived }
    }

    var archivedClients: [Client] {
        clients.filter { $0.archived }
    }

    // MARK: - Load Clients

    func loadClients(forceRefresh: Bool = false) async {
        if hasLoadedOnce && !forceRefresh && !clients.isEmpty {
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let userId = Database.shared.currentUserId else { return }

        do {
            let fetchedClients: [Client] = try await Database.shared
                .from(Database.Table.attendants)
                .select()
                .eq("professional_id", value: userId)
                .order("name")
                .execute()
                .value

            clients = fetchedClients
            hasLoadedOnce = true
        } catch {
            self.error = error
        }
    }

    // MARK: - Create Client

    func createClient(_ request: CreateClientRequest) async throws -> Client {
        guard let userId = Database.shared.currentUserId else {
            throw ClientError.notAuthenticated
        }

        let insertRequest = InsertClientRequest(
            professionalId: userId.uuidString,
            name: request.name,
            email: request.email,
            contactEmails: request.contactEmails,
            contactName: request.contactName,
            isSelfContact: request.isSelfContact,
            tags: request.tags,
            notes: request.notes
        )

        let client: Client = try await Database.shared
            .from(Database.Table.attendants)
            .insert(insertRequest)
            .select()
            .single()
            .execute()
            .value

        clients.append(client)
        clients.sort { $0.name < $1.name }

        return client
    }

    // MARK: - Update Client

    func updateClient(_ id: UUID, _ request: UpdateClientRequest) async throws {
        try await Database.shared
            .from(Database.Table.attendants)
            .update(request)
            .eq("id", value: id)
            .execute()

        await loadClients(forceRefresh: true)
    }

    // MARK: - Archive Client

    func archiveClient(_ id: UUID) async throws {
        try await updateClient(id, UpdateClientRequest(archived: true))
    }

    func unarchiveClient(_ id: UUID) async throws {
        try await updateClient(id, UpdateClientRequest(archived: false))
    }

    // MARK: - Delete Client

    func deleteClient(_ id: UUID) async throws {
        try await Database.shared
            .from(Database.Table.attendants)
            .delete()
            .eq("id", value: id)
            .execute()

        clients.removeAll { $0.id == id }
    }

    // MARK: - Get Client

    func getClient(_ id: UUID) -> Client? {
        clients.first { $0.id == id }
    }
}

enum ClientError: LocalizedError {
    case notAuthenticated
    case clientNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage clients"
        case .clientNotFound:
            return "Client not found"
        }
    }
}
