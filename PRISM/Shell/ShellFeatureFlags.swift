import Foundation

/// Shell V1 routing gate — legacy live surfaces stay in repo but are not mounted.
enum ShellFeatureFlags {
    static let shellV1Active = true
    static let legacyRoutesEnabled = false
    /// Flip to true only when Firebase session + CORTEX backbone are verified on device.
    static let brainConnected = false
}
