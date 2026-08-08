import Foundation
import Security

/// Shared session storage for the CORTEX Universe app family.
/// Uses a shared Keychain Access Group and App Group container so that
/// signing into any CORTEX app (CORTEX_, JERICHO, PRISM, FORGE, etc.)
/// makes the session available to all others — single sign-on across
/// the entire universe.
///
/// Requirements:
///   - All apps must have the same Team ID (72N4R2QL9Q)
///   - All apps must include "com.cortexnode.shared" in their
///     Keychain Access Groups entitlement
///   - All apps must include "group.com.cortexnode.shared" in their
///     App Groups entitlement
enum CXSharedSession {

    // MARK: - Constants

    /// Keychain access group shared across all CORTEX universe apps.
    /// Format: <TeamID>.<group-name>
    static let keychainAccessGroup = "72N4R2QL9Q.com.cortexnode.shared"

    /// App Group container ID for shared UserDefaults and files.
    static let appGroupIdentifier = "group.com.cortexnode.shared"

    // Keychain keys
    private static let sessionTokenKey = "cx.shared.sessionToken"
    private static let tierKey = "cx.shared.tier"
    private static let firebaseUIDKey = "cx.shared.firebaseUID"
    private static let expiresAtKey = "cx.shared.expiresAt"

    // MARK: - Shared UserDefaults

    /// Shared UserDefaults accessible by all apps in the group.
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Session Token (Keychain — shared across all CORTEX apps)

    /// Store the session token in the shared Keychain.
    static func saveSessionToken(_ token: String) {
        keychainWrite(key: sessionTokenKey, value: token)
    }

    /// Read the session token from the shared Keychain.
    static func getSessionToken() -> String? {
        keychainRead(key: sessionTokenKey)
    }

    /// Remove the session token from the shared Keychain (sign-out).
    static func clearSessionToken() {
        keychainDelete(key: sessionTokenKey)
        keychainDelete(key: tierKey)
        keychainDelete(key: firebaseUIDKey)
        keychainDelete(key: expiresAtKey)
        sharedDefaults?.removeObject(forKey: "cx.shared.lastSignIn")
    }

    // MARK: - Tier (shared so all apps know the subscription level)

    /// Store the user's current tier.
    static func saveTier(_ tier: String) {
        keychainWrite(key: tierKey, value: tier)
        sharedDefaults?.set(tier, forKey: "cx.shared.tier")
    }

    /// Read the user's tier.
    static func getTier() -> String? {
        keychainRead(key: tierKey) ?? sharedDefaults?.string(forKey: "cx.shared.tier")
    }

    // MARK: - Firebase UID

    static func saveFirebaseUID(_ uid: String) {
        keychainWrite(key: firebaseUIDKey, value: uid)
    }

    static func getFirebaseUID() -> String? {
        keychainRead(key: firebaseUIDKey)
    }

    // MARK: - Expiration

    static func saveExpiresAt(_ date: Date) {
        keychainWrite(key: expiresAtKey, value: ISO8601DateFormatter().string(from: date))
    }

    static func getExpiresAt() -> Date? {
        guard let str = keychainRead(key: expiresAtKey) else { return nil }
        return ISO8601DateFormatter().date(from: str)
    }

    static var isSessionExpired: Bool {
        guard let expires = getExpiresAt() else { return true }
        return Date() >= expires
    }

    // MARK: - Convenience

    /// Full sign-in: store token, tier, UID, expiry across all apps.
    static func signIn(token: String, tier: String, firebaseUID: String?, expiresAt: Date) {
        saveSessionToken(token)
        saveTier(tier)
        if let uid = firebaseUID { saveFirebaseUID(uid) }
        saveExpiresAt(expiresAt)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "cx.shared.lastSignIn")
    }

    /// Full sign-out: clear everything across all apps.
    static func signOut() {
        clearSessionToken()
    }

    /// Check if any valid session exists (not expired).
    static var hasValidSession: Bool {
        guard getSessionToken() != nil else { return false }
        return !isSessionExpired
    }

    // MARK: - Keychain Helpers

    private static func keychainWrite(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private static func keychainRead(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func keychainDelete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
