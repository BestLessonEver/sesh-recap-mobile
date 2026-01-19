import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared

    @State private var error: Error?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Status
                currentStatusCard

                // Plans
                if !subscriptionService.isProActive {
                    VStack(spacing: 16) {
                        Text("Upgrade to Pro")
                            .font(.title2)
                            .fontWeight(.bold)

                        ForEach(availablePackages, id: \.identifier) { package in
                            PackageCard(
                                package: package,
                                isSelected: false
                            ) {
                                purchase(package)
                            }
                        }

                        // Restore
                        Button("Restore Purchases") {
                            restore()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                // Features List
                featuresSection
            }
            .padding()
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if subscriptionService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: subscriptionService.isProActive ? "crown.fill" : "crown")
                .font(.system(size: 40))
                .foregroundStyle(subscriptionService.isProActive ? .yellow : .gray)

            Text(subscriptionService.isProActive ? "Pro" : "Free")
                .font(.title)
                .fontWeight(.bold)

            if subscriptionService.isProActive {
                if let expirationDate = subscriptionService.customerInfo?.entitlements["pro"]?.expirationDate {
                    Text("Renews \(expirationDate, style: .date)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Limited features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var availablePackages: [Package] {
        var packages: [Package] = []
        if let monthly = subscriptionService.monthlyPackage {
            packages.append(monthly)
        }
        if let yearly = subscriptionService.yearlyPackage {
            packages.append(yearly)
        }
        return packages
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's included")
                .font(.headline)

            FeatureRow(icon: "waveform", title: "Unlimited recordings", included: true)
            FeatureRow(icon: "sparkles", title: "AI-powered recaps", included: true)
            FeatureRow(icon: "envelope.fill", title: "Email delivery", included: true)
            FeatureRow(icon: "person.3.fill", title: "Team collaboration", included: subscriptionService.isProActive)
            FeatureRow(icon: "chart.bar.fill", title: "Analytics", included: subscriptionService.isProActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func purchase(_ package: Package) {
        Task {
            do {
                _ = try await subscriptionService.purchase(package)
            } catch {
                if (error as NSError).code != 1 { // User cancelled
                    self.error = error
                }
            }
        }
    }

    private func restore() {
        Task {
            do {
                _ = try await subscriptionService.restorePurchases()
            } catch {
                self.error = error
            }
        }
    }
}

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.packageType == .annual ? "Annual" : "Monthly")
                            .font(.headline)
                        Text(package.localizedPriceString)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if package.packageType == .annual {
                        Text("Save 20%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                if package.packageType == .annual {
                    Text("\(package.localizedPricePerMonth)/month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let included: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(included ? .blue : .gray)

            Text(title)
                .foregroundStyle(included ? .primary : .secondary)

            Spacer()

            Image(systemName: included ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(included ? .green : .gray)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
