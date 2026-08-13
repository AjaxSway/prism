import StoreKit
import Foundation

// MARK: - CORTEX Store Manager
// Handles all Apple IAP using StoreKit 2.
// Two subscription tiers: Pro ($39.99) and Operator ($199).
// Single source of truth for entitlements across the entire app.

@MainActor
@Observable
final class CortexStoreManager {
    static let shared = CortexStoreManager()

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case pro       = "com.cortexnode.prism.pro.monthly"
        case operator_ = "com.cortexnode.prism.operator.monthly"
    }

    // MARK: - Entitlement Tiers
    enum Tier: Int, Comparable {
        case free      = 0
        case pro       = 1
        case operator_ = 2

        static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }

        var label: String {
            switch self {
            case .free:      return "Free"
            case .pro:       return "Pro"
            case .operator_: return "Operator"
            }
        }

        var badge: String {
            switch self {
            case .free:      return "FREE"
            case .pro:       return "PRO"
            case .operator_: return "OPERATOR"
            }
        }
    }

    // MARK: - State
    var products: [Product] = []
    var currentTier: Tier = .free
    var isPurchasing: Bool = false
    var purchaseError: String? = nil
    var isLoading: Bool = false
    var transactionListener: Task<Void, Error>? = nil

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            products.sort { $0.price < $1.price }
        } catch {
            CortexLogger.send("[Store] Product load failed: \(error.localizedDescription)",
                              category: .system, level: .error)
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try CortexStoreManager.verified(verification)
                await refreshEntitlements()
                await transaction.finish()
                CortexLogger.send("[Store] Purchase complete: \(product.id)",
                                  category: .system, level: .info)
                return true
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            CortexLogger.send("[Store] Purchase error: \(error.localizedDescription)",
                              category: .system, level: .error)
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = "Restore failed. Please try again."
        }
    }

    // MARK: - Entitlement Check

    func refreshEntitlements() async {
        var highestTier: Tier = .free
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? CortexStoreManager.verified(result) else { continue }
            switch transaction.productID {
            case ProductID.operator_.rawValue, "ai.cortexnode.cortex.operator.monthly":
                highestTier = .operator_
            case ProductID.pro.rawValue, "ai.cortexnode.cortex.pro.monthly":
                if highestTier < .operator_ { highestTier = .pro }
            default:
                break
            }
        }
        currentTier = highestTier
    }

    // MARK: - Feature Gates

    var hasPro: Bool { currentTier >= .pro }
    var hasOperator: Bool { currentTier >= .operator_ }

    func hasAccess(to feature: CortexFeature) -> Bool {
        switch feature {
        case .persistentMemory, .premiumVoice, .smartRoutines, .multiDeviceSync, .signalZero, .prismCore:
            return hasPro
        case .jericho, .cortexNode, .prismFull, .unlimitedAutomations, .advancedAnalytics:
            return hasOperator
        }
    }

    // MARK: - Product Helpers

    var proProduct: Product? { products.first { $0.id == ProductID.pro.rawValue } }
    var operatorProduct: Product? { products.first { $0.id == ProductID.operator_.rawValue } }

    // MARK: - Transaction Listener
    // Task.detached is nonisolated — uses nonisolated static verified() to avoid actor isolation error.

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? CortexStoreManager.verified(result) {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verification (nonisolated static — safe to call from any context)

    nonisolated static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Feature Enum

enum CortexFeature {
    // Pro tier
    case persistentMemory
    case premiumVoice
    case smartRoutines
    case multiDeviceSync
    case signalZero
    case prismCore

    // Operator tier
    case jericho
    case cortexNode
    case prismFull
    case unlimitedAutomations
    case advancedAnalytics
}
