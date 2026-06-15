import Foundation

/// Production legal URLs — cortexnode.ai (App Store review + in-app Trust Center).
enum ShellLegalLinks {
    static let site = URL(string: "https://cortexnode.ai")!
    static let privacy = URL(string: "https://cortexnode.ai/privacy")!
    static let terms = URL(string: "https://cortexnode.ai/terms")!
    static let accountDeletion = URL(string: "https://cortexnode.ai/account-deletion")!
    static let aiSafety = URL(string: "https://cortexnode.ai/terms#ai-limitations")!
    static let subscriptionTerms = URL(string: "https://cortexnode.ai/terms#subscription-terms")!
    static let refundPolicy = URL(string: "https://cortexnode.ai/terms#refund-policy")!
    static let security = URL(string: "https://cortexnode.ai/security")!
    static let support = URL(string: "mailto:admin@cortexnode.ai")!
    static let pricing = URL(string: "https://cortexnode.ai/pricing")!
}
