import StoreKit
import Foundation
import Combine

// MARK: - Store Manager (GPL — all features free, no in-app purchases)

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var isPro: Bool = true
    @Published var isLifetime: Bool = true
    @Published var isReviewModeEnabled: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var restoreState: RestoreState = .idle
    @Published var subscriptionStatus: Any? = nil
    @Published var products: [Product] = []
    @Published var lastPurchasedProductId: String? = nil

    var monthlyProduct: Product? { products.first { $0.id == paullm_sshProducts.proMonthly } }
    var yearlyProduct: Product? { products.first { $0.id == paullm_sshProducts.proYearly } }
    var lifetimeProduct: Product? { products.first { $0.id == paullm_sshProducts.proLifetime } }

    private init() {}

    func loadProducts() async {}
    func purchase(_ product: Any) async {}
    func restorePurchases() async {}
    func checkEntitlements() async {
        isPro = true
        isLifetime = true
    }
    func enableReviewMode(code: String) -> Bool { true }
    func setReviewModeEnabled(_ enabled: Bool) {}

    var subscriptionExpirationDate: Date? { nil }
    var isSubscriptionActive: Bool { true }
    var hasActiveSubscriptionWithLifetime: Bool { true }
}
