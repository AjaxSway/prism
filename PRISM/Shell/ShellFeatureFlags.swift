import Foundation

/// Shell V1 routing gate — legacy live surfaces stay in repo but are not mounted.
enum ShellFeatureFlags {
    static let shellV1Active = true
    static let legacyRoutesEnabled = false
    /// Claude sets true when api.cortexnode.ai + auth verified. Until then: honest preview labels.
    static let brainConnected = false
}
