import AuthenticationServices
import Foundation

// MARK: - PRISM Gateway OAuth
// Blotato-style flow: ASWebAuthenticationSession → api.cortexnode.ai stores tokens → PRISM publishes via /publish.

struct GatewaySocialAccount: Identifiable, Codable, Equatable {
    let accountId: String
    let platform: String
    let handle: String?
    let platformUserId: String?
    let connectedAt: Double?

    var id: String { accountId }

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case platform
        case handle
        case platformUserId = "platform_user_id"
        case connectedAt = "connected_at"
    }

    func matches(_ platform: Platform) -> Bool {
        Self.normalizePlatform(platform) == Self.normalizePlatformString(self.platform)
    }

    static func normalizePlatform(_ platform: Platform) -> String {
        normalizePlatformString(platform.rawValue)
    }

    static func normalizePlatformString(_ raw: String) -> String {
        switch raw.uppercased() {
        case "X": return "x"
        case "IG": return "instagram"
        case "LI": return "linkedin"
        case "THREADS": return "threads"
        case "FB": return "facebook"
        case "YT": return "youtube"
        case "TIKTOK": return "tiktok"
        default: return raw.lowercased()
        }
    }
}

enum GatewayOAuthError: LocalizedError {
    case cancelled
    case noSession
    case badURL
    case serverError(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .cancelled: return "OAuth cancelled."
        case .noSession: return "Could not establish a secure session."
        case .badURL: return "Invalid gateway URL."
        case .serverError(let msg): return msg
        case .parseError: return "Could not read gateway response."
        }
    }
}

struct GatewayPublishResult: Decodable {
    let accountId: String
    let platform: String?
    let handle: String?
    let success: Bool
    let postUrl: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case platform, handle, success
        case postUrl = "post_url"
        case error
    }
}

@MainActor
final class PrismGatewayOAuthService: NSObject {
    static let shared = PrismGatewayOAuthService()

    private let apiBase = "https://api.cortexnode.ai"
    private var activeSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
    }

    // MARK: - OAuth launch

    func connect(platform: Platform) async throws {
        guard platform.usesGatewayOAuth else {
            throw GatewayOAuthError.serverError("\(platform.rawValue) uses on-device credentials.")
        }

        let token = try await AuthSessionStore.shared.validSessionToken()
        let segment = platform.gatewayOAuthSegment
        guard var components = URLComponents(string: "\(apiBase)/oauth/\(segment)/start") else {
            throw GatewayOAuthError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "app_redirect", value: "prism://oauth/success"),
        ]
        guard let startURL = components.url else { throw GatewayOAuthError.badURL }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: "prism"
            ) { url, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: GatewayOAuthError.cancelled)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: GatewayOAuthError.parseError)
                    return
                }
                continuation.resume(returning: url)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.activeSession = session
            if !session.start() {
                continuation.resume(throwing: GatewayOAuthError.serverError("Could not open OAuth browser."))
            }
        }

        _ = callbackURL
        activeSession = nil
        await PlatformChannelManager.shared.refreshGatewayAccounts()
    }

    // MARK: - Connections

    func fetchConnections() async throws -> [GatewaySocialAccount] {
        let token = try await AuthSessionStore.shared.validSessionToken()
        guard let url = URL(string: "\(apiBase)/oauth/connections") else {
            throw GatewayOAuthError.badURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GatewayOAuthError.parseError }
        if http.statusCode == 401 {
            await AuthSessionStore.shared.clearSessionToken()
            throw GatewayOAuthError.noSession
        }
        guard http.statusCode == 200 else {
            throw GatewayOAuthError.serverError("Connections failed (\(http.statusCode)).")
        }

        struct Payload: Decodable {
            let connections: [GatewaySocialAccount]
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw GatewayOAuthError.parseError
        }
        return payload.connections
    }

    func disconnect(accountId: String) async throws {
        let token = try await AuthSessionStore.shared.validSessionToken()
        guard let url = URL(string: "\(apiBase)/oauth/connections/\(accountId)") else {
            throw GatewayOAuthError.badURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GatewayOAuthError.serverError("Disconnect failed.")
        }
    }

    // MARK: - Publish

    func publish(content: String, accountIds: [String], imageURL: String? = nil) async throws -> [GatewayPublishResult] {
        let token = try await AuthSessionStore.shared.validSessionToken()
        guard let url = URL(string: "\(apiBase)/publish") else {
            throw GatewayOAuthError.badURL
        }

        var body: [String: Any] = [
            "content": content,
            "account_ids": accountIds,
        ]
        if let imageURL { body["image_url"] = imageURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw GatewayOAuthError.parseError }
        guard http.statusCode == 200 else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw GatewayOAuthError.serverError("Publish failed (\(http.statusCode)): \(snippet.prefix(120))")
        }

        struct Payload: Decodable {
            let results: [GatewayPublishResult]
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw GatewayOAuthError.parseError
        }
        return payload.results
    }
}

extension PrismGatewayOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return window
        }
        return scenes.flatMap(\.windows).first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}

extension Platform {
    var usesGatewayOAuth: Bool {
        switch self {
        case .bluesky: return false
        case .facebook, .tiktok: return false
        default: return true
        }
    }

    var gatewayOAuthSegment: String {
        switch self {
        case .x: return "x"
        case .instagram: return "instagram"
        case .linkedin: return "linkedin"
        case .threads: return "threads"
        case .youtube: return "google"
        default: return rawValue.lowercased()
        }
    }
}
