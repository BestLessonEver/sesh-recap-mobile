import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    Text((authViewModel.currentProfessional?.name.prefix(1) ?? "?").uppercased())
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(authViewModel.currentProfessional?.name ?? "User")
                                    .font(.headline)
                                Text(authViewModel.currentProfessional?.email ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Subscription Section
                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Label("Plan", systemImage: "crown.fill")
                            Spacer()
                            Text(subscriptionService.isProActive ? "Pro" : "Free")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Team Section
                if authViewModel.currentProfessional?.role == .owner ||
                   authViewModel.currentProfessional?.role == .admin {
                    Section("Team") {
                        NavigationLink {
                            TeamView()
                        } label: {
                            Label("Manage Team", systemImage: "person.3.fill")
                        }
                    }
                }

                // App Section
                Section("App") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("\(Environment.appVersion) (\(Environment.buildNumber))")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://seshrecap.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://seshrecap.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }

                    Link(destination: URL(string: "mailto:support@seshrecap.com")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
