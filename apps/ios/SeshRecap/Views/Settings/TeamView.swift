import SwiftUI

struct TeamView: View {
    @State private var teamMembers: [Professional] = []
    @State private var invitations: [Invitation] = []
    @State private var isLoading = false
    @State private var showInvite = false
    @State private var error: Error?

    var body: some View {
        List {
            Section("Team Members") {
                if teamMembers.isEmpty {
                    Text("No team members yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(teamMembers) { member in
                        TeamMemberRow(member: member)
                    }
                }
            }

            Section("Pending Invitations") {
                if invitations.isEmpty {
                    Text("No pending invitations")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(invitations) { invitation in
                        InvitationRow(invitation: invitation) {
                            cancelInvitation(invitation)
                        }
                    }
                }
            }
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInvite = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .refreshable {
            await loadTeam()
        }
        .sheet(isPresented: $showInvite) {
            InviteTeamMemberView { email, role in
                await inviteMember(email: email, role: role)
            }
        }
        .task {
            await loadTeam()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private func loadTeam() async {
        isLoading = true
        defer { isLoading = false }

        guard let userId = SupabaseClient.shared.currentUserId else { return }

        do {
            // Get current user's organization
            let professional: Professional = try await SupabaseClient.shared
                .from(SupabaseClient.Table.professionals)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            guard let orgId = professional.organizationId else { return }

            // Get team members
            let members: [Professional] = try await SupabaseClient.shared
                .from(SupabaseClient.Table.professionals)
                .select()
                .eq("organization_id", value: orgId)
                .execute()
                .value

            teamMembers = members

            // Get pending invitations
            let invites: [Invitation] = try await SupabaseClient.shared
                .from(SupabaseClient.Table.invitations)
                .select()
                .eq("organization_id", value: orgId)
                .eq("used", value: false)
                .execute()
                .value

            invitations = invites.filter { $0.expiresAt > Date() }
        } catch {
            self.error = error
        }
    }

    private func inviteMember(email: String, role: String) async {
        guard let userId = SupabaseClient.shared.currentUserId else { return }

        do {
            let professional: Professional = try await SupabaseClient.shared
                .from(SupabaseClient.Table.professionals)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            guard let orgId = professional.organizationId else { return }

            let token = UUID().uuidString
            let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

            try await SupabaseClient.shared
                .from(SupabaseClient.Table.invitations)
                .insert([
                    "organization_id": orgId.uuidString,
                    "email": email,
                    "token": token,
                    "role": role,
                    "expires_at": ISO8601DateFormatter().string(from: expiresAt)
                ])
                .execute()

            await loadTeam()
        } catch {
            self.error = error
        }
    }

    private func cancelInvitation(_ invitation: Invitation) {
        Task {
            do {
                try await SupabaseClient.shared
                    .from(SupabaseClient.Table.invitations)
                    .delete()
                    .eq("id", value: invitation.id)
                    .execute()

                invitations.removeAll { $0.id == invitation.id }
            } catch {
                self.error = error
            }
        }
    }
}

struct TeamMemberRow: View {
    let member: Professional

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(member.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.body)
                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(member.role.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor.opacity(0.2))
                .foregroundStyle(roleColor)
                .clipShape(Capsule())
        }
    }

    private var roleColor: Color {
        switch member.role {
        case .owner: return .purple
        case .admin: return .blue
        case .member: return .gray
        }
    }
}

struct InvitationRow: View {
    let invitation: Invitation
    let onCancel: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(invitation.email)
                    .font(.body)
                Text("Expires \(invitation.expiresAt, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

struct InviteTeamMemberView: View {
    @Environment(\.dismiss) private var dismiss

    let onInvite: (String, String) async -> Void

    @State private var email = ""
    @State private var role = "member"
    @State private var isInviting = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                Picker("Role", selection: $role) {
                    Text("Member").tag("member")
                    Text("Admin").tag("admin")
                }
            }
            .navigationTitle("Invite Team Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        invite()
                    }
                    .disabled(email.isEmpty || !email.contains("@") || isInviting)
                }
            }
            .disabled(isInviting)
        }
    }

    private func invite() {
        isInviting = true
        Task {
            await onInvite(email, role)
            dismiss()
        }
    }
}

struct Invitation: Codable, Identifiable {
    let id: UUID
    let organizationId: UUID
    let email: String
    let token: String
    let role: String
    let expiresAt: Date
    let used: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case email
        case token
        case role
        case expiresAt = "expires_at"
        case used
        case createdAt = "created_at"
    }
}

#Preview {
    NavigationStack {
        TeamView()
    }
}
