import Foundation
import RevenueCat

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var offerings: Offerings?
    @Published private(set) var isProActive = false
    @Published private(set) var isLoading = false

    private let proEntitlementIdentifier = "pro"

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    func configure(userId: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConfig.revenueCatAPIKey, appUserID: userId)

        Purchases.shared.delegate = self

        Task {
            await refreshCustomerInfo()
            await fetchOfferings()
        }
    }

    // MARK: - Customer Info

    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = info
                self.isProActive = info.entitlements[proEntitlementIdentifier]?.isActive == true
            }
        } catch {
            print("Failed to get customer info: \(error)")
        }
    }

    // MARK: - Offerings

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offerings = offerings
            }
        } catch {
            print("Failed to fetch offerings: \(error)")
        }
    }

    // MARK: - Purchases

    func purchase(_ package: Package) async throws -> CustomerInfo {
        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let result = try await Purchases.shared.purchase(package: package)

        await MainActor.run {
            self.customerInfo = result.customerInfo
            self.isProActive = result.customerInfo.entitlements[proEntitlementIdentifier]?.isActive == true
        }

        return result.customerInfo
    }

    func restorePurchases() async throws -> CustomerInfo {
        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let info = try await Purchases.shared.restorePurchases()

        await MainActor.run {
            self.customerInfo = info
            self.isProActive = info.entitlements[proEntitlementIdentifier]?.isActive == true
        }

        return info
    }

    // MARK: - Helpers

    var currentOffering: Offering? {
        offerings?.current
    }

    var monthlyPackage: Package? {
        currentOffering?.monthly
    }

    var yearlyPackage: Package? {
        currentOffering?.annual
    }

    var trialDays: Int? {
        guard let intro = monthlyPackage?.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else {
            return nil
        }
        return intro.subscriptionPeriod.value
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isProActive = customerInfo.entitlements[proEntitlementIdentifier]?.isActive == true
        }
    }
}

// MARK: - Price Formatting

extension Package {
    var localizedPriceString: String {
        storeProduct.localizedPriceString
    }

    var localizedPricePerMonth: String {
        let price = storeProduct.price as Decimal
        let months: Decimal
        switch packageType {
        case .annual:
            months = 12
        case .sixMonth:
            months = 6
        case .threeMonth:
            months = 3
        case .monthly, .weekly:
            months = 1
        default:
            months = 1
        }

        let monthlyPrice = price / months
        
        // Use priceFormatter if available, otherwise create a formatter
        if let formatter = storeProduct.priceFormatter {
            return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? localizedPriceString
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? localizedPriceString
        }
    }
}
