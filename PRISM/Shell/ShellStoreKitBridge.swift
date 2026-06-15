import Foundation

/// StoreKit 2 bridge — Claude / Codex implements product IDs before paid in-app unlock.
/// Until IAP is live, subscriptions are managed at cortexnode.ai (review notes document this).
protocol ShellSubscriptionServing: Sendable {
    var hasActiveSubscription: Bool { get async }
    func restorePurchases() async throws
    func productIDs(for appKind: ShellAppKind) -> [String]
}

struct ShellPreviewSubscriptionService: ShellSubscriptionServing {
    var hasActiveSubscription: Bool { get async { false } }

    func restorePurchases() async throws {
        throw ShellStoreKitError.notConfigured
    }

    func productIDs(for appKind: ShellAppKind) -> [String] {
        switch appKind {
        case .cortexNode: return ["com.cortexnode.cortexnode.pro.monthly"]
        case .jericho: return ["com.cortexnode.jericho.pro.monthly"]
        case .prism: return ["com.cortexnode.prism.pro.monthly"]
        }
    }
}

enum ShellStoreKitError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "In-app purchases configure in App Store Connect before paid unlock."
    }
}
