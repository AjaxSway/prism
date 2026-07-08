import Foundation
import Security

// MARK: - CORTEX Universe Brain Client
// One brain · seven doors. Every standalone app talks to api.cortexnode.ai/v1/chat.

struct CortexBrainMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable { case user, assistant, system }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum CortexBrainError: LocalizedError {
    case offline
    case unauthorized
    case server(Int)
    case parse
    case empty

    var errorDescription: String? {
        switch self {
        case .offline: return "CORTEX brain unreachable. Check your connection."
        case .unauthorized: return "Session expired. Restart the app to reconnect."
        case .server(let c): return "Brain returned status \(c). Try again."
        case .parse: return "Could not read the brain response."
        case .empty: return "Brain returned an empty response."
        }
    }
}

@MainActor
final class CortexUniverseBrain: ObservableObject {
    static let shared = CortexUniverseBrain()

    @Published private(set) var messages: [CortexBrainMessage] = []
    @Published private(set) var isThinking = false

    private let chatURL = "https://api.cortexnode.ai/v1/chat"
    private let session = CortexDeviceSession.shared
    private var historyKey: String { "cortex.chat.\(surfaceKey)" }
    private var surfaceKey: String = "cortex"
    private var systemPrompt: String = ""

    /// Truth-based pulse state for SharedCortexBrainPulseView — never fake LIVE.
    var pulseState: CortexBrainPulseState {
        if isThinking { return .thinking }
        if let last = messages.last, last.role == .system {
            let text = last.content.lowercased()
            if text.contains("unreachable") || text.contains("offline") || text.contains("connection") {
                return .offline
            }
            return .error
        }
        return .idle
    }

    var pulseApp: CortexBrainPulseApp {
        switch surfaceKey {
        case "forge": return .forge
        case "atlas": return .atlas
        case "jericho": return .jericho
        case "prism": return .prism
        case "cortexnode", "node": return .cortexnode
        case "signalzero", "signal-zero": return .signalZero
        default: return .cortex
        }
    }

    func configure(surface: String, systemPrompt: String) {
        self.surfaceKey = surface
        self.systemPrompt = systemPrompt
        loadHistory()
    }

    func send(_ userText: String) async -> String {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard !isThinking else { return "" }

        let userMsg = CortexBrainMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        saveHistory()
        isThinking = true
        defer { isThinking = false }

        do {
            let reply = try await requestBrain(user: trimmed)
            let assistant = CortexBrainMessage(role: .assistant, content: reply)
            messages.append(assistant)
            saveHistory()
            return reply
        } catch {
            let text = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let system = CortexBrainMessage(role: .system, content: text)
            messages.append(system)
            saveHistory()
            return text
        }
    }

    func clearHistory() {
        messages.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func requestBrain(user: String) async throws -> String {
        let token = try await session.validToken(appLabel: surfaceKey)
        guard let url = URL(string: chatURL) else { throw CortexBrainError.parse }

        var historyPayload: [[String: String]] = messages
            .filter { $0.role != .system }
            .suffix(12)
            .map { ["role": $0.role == .user ? "user" : "assistant", "content": $0.content] }

        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "stream": false,
            "system": systemPrompt,
            "messages": historyPayload
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw CortexBrainError.offline }
        if http.statusCode == 401 || http.statusCode == 403 {
            await session.clearToken()
            throw CortexBrainError.unauthorized
        }
        guard http.statusCode == 200 else { throw CortexBrainError.server(http.statusCode) }

        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CortexBrainError.parse
        }
        if let content = obj["content"] as? String, !content.isEmpty { return content }
        if let choices = obj["choices"] as? [[String: Any]],
           let msg = choices.first?["message"] as? [String: Any],
           let text = msg["content"] as? String, !text.isEmpty { return text }
        throw CortexBrainError.empty
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let saved = try? JSONDecoder().decode([CortexBrainMessage].self, from: data) else { return }
        messages = saved
    }

    private func saveHistory() {
        let recent = Array(messages.suffix(80))
        guard let data = try? JSONEncoder().encode(recent) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
}

// MARK: - Device session (no Firebase required for satellite apps)

actor CortexDeviceSession {
    static let shared = CortexDeviceSession()
    private let endpoint = "https://api.cortexnode.ai/v1/auth/session-token"
    private let service = "ai.cortexnode.universe.session"

    func validToken(appLabel: String) async throws -> String {
        if let cached = read(account: "token"),
           let exp = read(account: "exp"),
           let ts = TimeInterval(exp),
           Date(timeIntervalSince1970: ts).timeIntervalSinceNow > 60 {
            return cached
        }
        return try await fetch(appLabel: appLabel)
    }

    func clearToken() {
        delete(account: "token")
        delete(account: "exp")
    }

    private func fetch(appLabel: String) async throws -> String {
        guard let url = URL(string: endpoint) else { throw CortexBrainError.offline }
        let deviceId = stableDeviceId()
        let info = Bundle.main.infoDictionary ?? [:]
        var req = URLRequest(url: url, timeoutInterval: 12)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(deviceId, forHTTPHeaderField: "X-Cortex-Device-Id")
        req.setValue("\(appLabel) iOS", forHTTPHeaderField: "X-Cortex-Device-Name")
        req.setValue("ios_app", forHTTPHeaderField: "X-Cortex-Device-Role")
        let body: [String: Any] = [
            "platform": "ios",
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "app_version": info["CFBundleShortVersionString"] as? String ?? "1.0",
            "build_number": info["CFBundleVersion"] as? String ?? "1",
            "device_id": deviceId
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String, !token.isEmpty,
              let expiresIn = json["expires_in"] as? Int, expiresIn > 0 else {
            throw CortexBrainError.offline
        }
        let exp = Date().timeIntervalSince1970 + Double(expiresIn)
        write(token, account: "token")
        write(String(exp), account: "exp")
        return token
    }

    private func stableDeviceId() -> String {
        if let id = read(account: "device"), !id.isEmpty { return id }
        let id = UUID().uuidString
        write(id, account: "device")
        return id
    }

    private func read(account: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String, account: String) {
        delete(account: account)
        guard let data = value.data(using: .utf8) else { return }
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        SecItemAdd(q as CFDictionary, nil)
    }

    private func delete(account: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
    }
}
