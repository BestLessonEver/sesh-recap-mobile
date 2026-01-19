import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        NavigationLink {
                            ProfileView()
                        } label: {
                            BrandCard(padding: 16) {
                                HStack(spacing: 16) {
                                    GradientAvatar(
                                        name: authViewModel.currentProfessional?.name ?? "U",
                                        size: 56
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(authViewModel.currentProfessional?.name ?? "User")
                                            .font(.headline)
                                            .foregroundStyle(Color.textPrimary)
                                        Text(authViewModel.currentProfessional?.email ?? "")
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color.textTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Subscription Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SUBSCRIPTION")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textTertiary)
                                .padding(.horizontal, 4)

                            NavigationLink {
                                SubscriptionView()
                            } label: {
                                BrandCard(padding: 16) {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.brandGold.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "crown.fill")
                                                .foregroundStyle(Color.brandGold)
                                        }

                                        Text("Plan")
                                            .foregroundStyle(Color.textPrimary)

                                        Spacer()

                                        Text(subscriptionService.isProActive ? "Pro" : "Free")
                                            .foregroundStyle(Color.textSecondary)

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Team Section
                        if authViewModel.currentProfessional?.role == .owner ||
                           authViewModel.currentProfessional?.role == .admin {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("TEAM")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textTertiary)
                                    .padding(.horizontal, 4)

                                NavigationLink {
                                    TeamView()
                                } label: {
                                    BrandCard(padding: 16) {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.brandPink.opacity(0.15))
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: "person.3.fill")
                                                    .foregroundStyle(Color.brandPink)
                                            }

                                            Text("Manage Team")
                                                .foregroundStyle(Color.textPrimary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(Color.textTertiary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // App Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APP")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textTertiary)
                                .padding(.horizontal, 4)

                            BrandCard(padding: 0) {
                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "info.circle",
                                        iconColor: .textSecondary,
                                        title: "Version",
                                        value: "\(AppConfig.appVersion) (\(AppConfig.buildNumber))"
                                    )

                                    Divider()
                                        .background(Color.border)

                                    SettingsLinkRow(
                                        icon: "hand.raised.fill",
                                        iconColor: .brandPink,
                                        title: "Privacy Policy",
                                        url: "https://seshrecap.com/privacy"
                                    )

                                    Divider()
                                        .background(Color.border)

                                    SettingsLinkRow(
                                        icon: "doc.text.fill",
                                        iconColor: .brandGold,
                                        title: "Terms of Service",
                                        url: "https://seshrecap.com/terms"
                                    )

                                    Divider()
                                        .background(Color.border)

                                    SettingsLinkRow(
                                        icon: "envelope.fill",
                                        iconColor: .success,
                                        title: "Contact Support",
                                        url: "mailto:support@seshrecap.com"
                                    )
                                }
                            }
                        }

                        // Sign Out
                        Button {
                            showSignOutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .foregroundStyle(Color.error)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text(value)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(16)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
