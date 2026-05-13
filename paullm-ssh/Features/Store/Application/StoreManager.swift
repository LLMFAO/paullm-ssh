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
    @Published var products: [Any] = []
    @Published var lastPurchasedProductId: String? = nil

    var monthlyProduct: Any? { nil }
    var yearlyProduct: Any? { nil }
    var lifetimeProduct: Any? { nil }

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
