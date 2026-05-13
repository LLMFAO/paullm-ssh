import Foundation

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case failed(String)

    static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing), (.purchased, .purchased):
            return true
        case (.failed(let lhsMessage), .failed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

enum RestoreState: Equatable {
    case idle
    case restoring
    case restored(hasAccess: Bool)
    case failed(String)

    static func == (lhs: RestoreState, rhs: RestoreState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.restoring, .restoring):
            return true
        case (.restored(let lhsHasAccess), .restored(let rhsHasAccess)):
            return lhsHasAccess == rhsHasAccess
        case (.failed(let lhsMessage), .failed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

enum paullm_sshProducts {
    static let proMonthly = "app.paullm.ssh.pro.monthly"
    static let proYearly = "app.paullm.ssh.pro.yearly"
    static let proLifetime = "app.paullm.ssh.pro.lifetime"

    static let subscriptionGroupId = "paullm_pro"
    static let allProducts = [proMonthly, proYearly, proLifetime]
}

enum StoreError: LocalizedError {
    case verificationFailed
    case productNotFound
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return String(localized: "Purchase verification failed")
        case .productNotFound:
            return String(localized: "Product not found")
        case .purchaseFailed(let message):
            return String(format: String(localized: "Purchase failed: %@"), message)
        }
    }
}
