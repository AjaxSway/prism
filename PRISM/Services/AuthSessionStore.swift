import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AuthSessionStore
// Manages short-lived server-issued session tokens for CORTEX API calls.
//
// Flow:
//   1. On first request -> request a device-scoped session JWT via /v1/auth/session-token
//   2. Cache session JWT in Keychain with expiry timestamp
//   3. On subsequent requests → return cached token if not near expiry
//   4. Auto-refresh when < 60s remain on current session
//   5. On 401 from API → clear session, next call triggers fresh exchange
//
// No static bearer is sent by the client. Session issuance is governed server-side
// by bundle allowlists, device allowlists, and future App Attest validation.

actor AuthSessionStore {
    static let shared = AuthSessionStore()
    private init() {}

    private let sessionEndpoint = "https://api.cortexnode.ai/v1/auth/session-token"
    private let sessionService  = "ai.cortexnode.session"
    private let sessionAccount  = "session.token"
    private let expiryAccount   = "session.expiry"
    private let deviceAccount   = "device.id"

    // MARK: - Public API

    func validSessionToken() async throws -> String {
        if let cached = cachedToken(), !isNearExpiry() {
            return cached
        }
        return try await refreshSessionToken()
    }

    func clearSessionToken() {
        keychainDelete(service: sessionService, account: sessionAccount)
        keychainDelete(service: sessionService, account: expiryAccount)
    }

    // MARK: - Refresh

    private func refreshSessionToken() async throws -> String {
        let deviceId = stableDeviceId()
        guard !deviceId.isEmpty else {
            throw AuthSessionError.noBearerToken
        }
        guard let url = URL(string: sessionEndpoint) else {
            throw AuthSessionError.invalidEndpoint
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        req.setValue(deviceId,              forHTTPHeaderField: "X-Cortex-Device-Id")
        req.setValue(deviceDisplayName(),   forHTTPHeaderField: "X-Cortex-Device-Name")
        req.setValue("ios_app",             forHTTPHeaderField: "X-Cortex-Device-Role")

        let bundleId  = Bundle.main.bundleIdentifier ?? ""
        let version   = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build     = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        let body: [String: Any] = [
            "platform":       "ios",
            "bundle_id":      bundleId,
            "device_id":      deviceId,
            "app_version":    version,
            "build_number":   build
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthSessionError.issuanceFailed
        }
        guard let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token  = json["access_token"]  as? String,
              let expStr = json["expires_at"]     as? String else {
            throw AuthSessionError.malformedResponse
        }

        keychainWrite(value: token, service: sessionService, account: sessionAccount)
        if let expDate = ISO8601DateFormatter().date(from: expStr) {
            keychainWrite(value: String(expDate.timeIntervalSince1970),
                          service: sessionService, account: expiryAccount)
        }
        return token
    }

    // MARK: - Helpers

    private func cachedToken() -> String? {
        keychainRead(service: sessionService, account: sessionAccount)
    }

    private func isNearExpiry() -> Bool {
        guard let ts  = keychainRead(service: sessionService, account: expiryAccount),
              let exp = Double(ts) else { return true }
        return Date().timeIntervalSince1970 > exp - 60
    }

    private func stableDeviceId() -> String {
        if let existing = keychainRead(service: sessionService, account: deviceAccount),
           !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        keychainWrite(value: id, service: sessionService, account: deviceAccount)
        return id
    }

    private func deviceDisplayName() -> String {
        "PRISM iOS"
    }

    // MARK: - Keychain

    private func keychainRead(service: String, account: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func keychainWrite(value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let base: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        var attrs = base
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private func keychainDelete(service: String, account: String) {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
    }
}

// MARK: - Errors

enum AuthSessionError: LocalizedError {
    case noBearerToken
    case invalidEndpoint
    case issuanceFailed
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .noBearerToken:      return "Device identity is unavailable. Reinstall or re-authenticate this app."
        case .invalidEndpoint:    return "Session endpoint URL is invalid."
        case .issuanceFailed:     return "Could not establish a secure session. Check connectivity."
        case .malformedResponse:  return "Session response could not be parsed."
        }
    }
}
