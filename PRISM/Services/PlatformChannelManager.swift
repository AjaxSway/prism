import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Channel Manager
// Gateway OAuth accounts (server-side tokens) + Bluesky native (on-device app password).

@MainActor
@Observable
final class PlatformChannelManager {
    static let shared = PlatformChannelManager()
    private init() {
        loadAll()
        Task { await refreshGatewayAccounts() }
    }

    var connections: [Platform: PlatformConnection] = [:]
    var gatewayAccounts: [GatewaySocialAccount] = []

    func connection(for platform: Platform) -> PlatformConnection {
        connections[platform] ?? PlatformConnection(platform: platform)
    }

    func gatewayAccounts(for platform: Platform) -> [GatewaySocialAccount] {
        gatewayAccounts.filter { $0.matches(platform) }
    }

    func isConnected(_ platform: Platform) -> Bool {
        if platform == .bluesky {
            return connections[platform]?.isConnected == true
        }
        return !gatewayAccounts(for: platform).isEmpty
    }

    var connectedCount: Int {
        let gatewayPlatforms = Set(gatewayAccounts.map { GatewaySocialAccount.normalizePlatformString($0.platform) })
        let bluesky = connections[.bluesky]?.isConnected == true ? 1 : 0
        return gatewayPlatforms.count + bluesky
    }

    var totalAccountCount: Int {
        gatewayAccounts.count + (connections[.bluesky]?.isConnected == true ? 1 : 0)
    }

    func accountIds(for platforms: [Platform]) -> [String] {
        platforms.flatMap { platform in
            gatewayAccounts(for: platform).map(\.accountId)
        }
    }

    func refreshGatewayAccounts() async {
        do {
            gatewayAccounts = try await PrismGatewayOAuthService.shared.fetchConnections()
            syncLegacyConnectionsFromGateway()
        } catch {
            // Offline or session not ready — keep cached gateway list empty
        }
    }

    func disconnectGatewayAccount(_ account: GatewaySocialAccount) async throws {
        try await PrismGatewayOAuthService.shared.disconnect(accountId: account.accountId)
        gatewayAccounts.removeAll { $0.accountId == account.accountId }
    }

    /// Mirror first gateway account into legacy connection slot for dispatch compatibility.
    private func syncLegacyConnectionsFromGateway() {
        for platform in Platform.allCases where platform.usesGatewayOAuth {
            if let first = gatewayAccounts(for: platform).first {
                connections[platform] = PlatformConnection(
                    platform: platform,
                    handle: first.handle,
                    accessToken: "gateway",
                    isConnected: true
                )
            } else {
                connections[platform] = PlatformConnection(platform: platform)
            }
        }
    }

    // MARK: - Save / clear credentials

    func saveConnection(_ connection: PlatformConnection) {
        connections[connection.platform] = connection

        let key = keychainKey(for: connection.platform)
        guard let token = connection.accessToken,
              let data = token.data(using: .utf8) else { return }

        keychainWrite(data: data, account: key)

        if let handle = connection.handle,
           let handleData = handle.data(using: .utf8) {
            keychainWrite(data: handleData, account: "\(key).handle")
        }
        if let extra = connection.extraToken,
           let extraData = extra.data(using: .utf8) {
            keychainWrite(data: extraData, account: "\(key).extra")
        }
    }

    func disconnect(_ platform: Platform) {
        if platform == .bluesky {
            connections[platform] = PlatformConnection(platform: platform)
            let key = keychainKey(for: platform)
            keychainDelete(account: key)
            keychainDelete(account: "\(key).handle")
            keychainDelete(account: "\(key).extra")
        }
    }

    // MARK: - Load from Keychain on init

    private func loadAll() {
        for platform in Platform.allCases where platform == .bluesky {
            let key = keychainKey(for: platform)
            guard let token = keychainRead(account: key) else { continue }
            let handle = keychainRead(account: "\(key).handle")
            let extra  = keychainRead(account: "\(key).extra")
            connections[platform] = PlatformConnection(
                platform: platform,
                handle: handle,
                accessToken: token,
                extraToken: extra,
                isConnected: true
            )
        }
    }

    // MARK: - Keychain

    private let service = "ai.cortexnode.prism.platforms"

    private func keychainKey(for platform: Platform) -> String {
        "platform.\(platform.rawValue.lowercased())"
    }

    private func keychainWrite(data: Data, account: String) {
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

    private func keychainRead(account: String) -> String? {
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

    private func keychainDelete(account: String) {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
    }
}

// MARK: - Platform Connection model

struct PlatformConnection {
    let platform: Platform
    var handle: String?
    var accessToken: String?
    var extraToken: String?  // refresh token, app secret, etc.
    var isConnected: Bool

    init(platform: Platform, handle: String? = nil, accessToken: String? = nil, extraToken: String? = nil, isConnected: Bool = false) {
        self.platform = platform
        self.handle = handle
        self.accessToken = accessToken
        self.extraToken = extraToken
        self.isConnected = isConnected
    }
}

// MARK: - Per-platform OAuth instructions

extension Platform {
    var connectInstructions: PlatformConnectInstructions {
        switch self {
        case .bluesky:
            return PlatformConnectInstructions(
                title: "Connect Bluesky",
                steps: [
                    "Go to bsky.app → Settings → Privacy and Security",
                    "Tap App Passwords → Add App Password",
                    "Name it PRISM and copy the password",
                    "Enter your handle (@you.bsky.social) and app password below"
                ],
                fields: [.handle, .appPassword],
                authType: .appPassword
            )
        case .x:
            return PlatformConnectInstructions(
                title: "Connect X (Twitter)",
                steps: [
                    "Tap Connect with Gateway below",
                    "Sign in to X in the secure browser",
                    "Tokens stay on api.cortexnode.ai — never on your device",
                    "Add multiple X accounts with Add Account"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .instagram:
            return PlatformConnectInstructions(
                title: "Connect Instagram",
                steps: [
                    "Tap Connect with Gateway below",
                    "Authorize PRISM via Meta / Instagram",
                    "Server stores your long-lived token securely"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .facebook:
            return PlatformConnectInstructions(
                title: "Connect Facebook",
                steps: [
                    "Facebook Page OAuth is coming to the gateway",
                    "Check back after the next server deploy"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .threads:
            return PlatformConnectInstructions(
                title: "Connect Threads",
                steps: [
                    "Tap Connect with Gateway below",
                    "Sign in with your Threads / Meta account",
                    "Post directly — no Blotato middleman"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .linkedin:
            return PlatformConnectInstructions(
                title: "Connect LinkedIn",
                steps: [
                    "Tap Connect with Gateway below",
                    "Authorize PRISM on LinkedIn",
                    "w_member_social scope enables native posting"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .youtube:
            return PlatformConnectInstructions(
                title: "Connect YouTube",
                steps: [
                    "Tap Connect with Gateway below",
                    "Sign in with Google / YouTube",
                    "Channel tokens stored server-side on CORTEX"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        case .tiktok:
            return PlatformConnectInstructions(
                title: "Connect TikTok",
                steps: [
                    "TikTok Content API OAuth is coming to the gateway",
                    "Check back after the next server deploy"
                ],
                fields: [],
                authType: .gatewayOAuth
            )
        }
    }
}

struct PlatformConnectInstructions {
    let title: String
    let steps: [String]
    let fields: [ConnectField]
    let authType: ConnectAuthType
}

enum ConnectField {
    case handle, appPassword, accessToken, refreshToken, clientID, clientSecret, pageID
    var label: String {
        switch self {
        case .handle:        return "Handle (e.g. @you.bsky.social)"
        case .appPassword:   return "App Password"
        case .accessToken:   return "Access Token"
        case .refreshToken:  return "Refresh Token"
        case .clientID:      return "Client ID"
        case .clientSecret:  return "Client Secret"
        case .pageID:        return "Page ID"
        }
    }
    var isSecure: Bool {
        self != .handle && self != .pageID
    }
}

enum ConnectAuthType {
    case appPassword, oauth2, gatewayOAuth
}
