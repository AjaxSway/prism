import Foundation

// MARK: - Super Brain types (Signal Zero CLI pattern · api.cortexnode.ai/v1/chat)

enum CortexSpecialtyLens: String, Sendable, CaseIterable {
    case cortexNode
    case jericho
    case prism
    case forge
    case aurion
    case signalZero

    init(shellAppKind: ShellAppKind) {
        switch shellAppKind {
        case .cortexNode: self = .cortexNode
        case .jericho: self = .jericho
        case .prism: self = .prism
        }
    }

    var surfaceHeader: String {
        switch self {
        case .cortexNode: return "cortexnode"
        case .jericho: return "jericho"
        case .prism: return "prism"
        case .forge: return "forge"
        case .aurion: return "aurion"
        case .signalZero: return "signal-zero"
        }
    }

    var deviceLabel: String {
        switch self {
        case .cortexNode: return "CORTEXNODE iOS"
        case .jericho: return "JERICHO iOS"
        case .prism: return "PRISM iOS"
        case .forge: return "FORGE iOS"
        case .aurion: return "AURION iOS"
        case .signalZero: return "Signal Zero"
        }
    }

    var systemPrompt: String {
        Self.basePrompt(for: self) + "\n\n" + truthBoundary
    }

    private static func basePrompt(for lens: CortexSpecialtyLens) -> String {
        let core = """
        You are CORTEX — Sir's personal intelligence layer. Address Sir as Sir. Be precise, honest, and action-oriented. \
        Never claim live runtime state unless proven. Use connect-later language when wiring is absent.
        """
        switch lens {
        case .cortexNode:
            return core + """

            APP: CORTEXNODE
            You are CORTEX through the CORTEXNODE lens.
            Focus on ecosystem structure, app relationships, node health, account surfaces, sync posture, platform architecture, and system map clarity.
            """
        case .jericho:
            return core + """

            APP: JERICHO
            You are CORTEX through the JERICHO lens.
            Focus on trust, risk, permission gates, policy guardrails, audit trails, integrity checks, and boundary rules.
            """
        case .prism:
            return core + """

            APP: PRISM
            You are CORTEX through the PRISM lens.
            Focus on Studio, signal creation, refraction, platform-ready outputs, brand voice, proof assets, draft queue, approval gates, campaign calendar, audit trail, and distribution readiness.
            """
        case .forge:
            return core + """

            APP: FORGE
            You are CORTEX through the FORGE lens.
            Focus on building, artifacts, proof, implementation steps, code structure, file plans, validation, and shipping discipline.
            """
        case .aurion:
            return core + """

            APP: AURION
            You are CORTEX through the AURION lens.
            Focus on pressure, command decisions, momentum, mission gates, proof requirements, and victory protocol.
            """
        case .signalZero:
            return core + """

            APP: SIGNAL ZERO
            You are CORTEX through the SIGNAL ZERO lens.
            Focus on command, execution, terminal automation, approval gates, and operator control.
            """
        }
    }

    private var truthBoundary: String {
        switch self {
        case .cortexNode:
            return """
            TRUTH BOUNDARY (CORTEXNODE):
            No fake live telemetry. No fake connected accounts. Use connect-later language when runtime is absent.
            """
        case .jericho:
            return """
            TRUTH BOUNDARY (JERICHO):
            Advisory only unless runtime-backed. No antivirus claims. No unhackable claims. No device-wide protection claims. No fake armed or live security claims.
            """
        case .prism:
            return """
            TRUTH BOUNDARY (PRISM):
            Draft-only until operator approval. No fake publishing. No fake image generation. Operator approval required before publish.
            """
        case .forge:
            return """
            TRUTH BOUNDARY (FORGE):
            No fake build proof. No fake deployment. No fake green status without logs.
            """
        case .aurion:
            return """
            TRUTH BOUNDARY (AURION):
            Mock-only unless wired. No fake mission success. No fake live command authority.
            """
        case .signalZero:
            return """
            TRUTH BOUNDARY (SIGNAL ZERO):
            Execute only through verified routes. No simulated tool calls.
            """
        }
    }
}

enum BrainConnectionState: String, Sendable {
    case offline = "Brain unavailable"
    case connecting = "Connecting"
    case connected = "Brain connected"
    case error = "Super Brain route unavailable"
    case preview = "Shell preview"
}

enum BrainTruthMode: String, Sendable {
    case runtime
    case shellPreview
    case offlinePreview
}

struct CortexBrainRequest: Sendable {
    let prompt: String
    let lens: CortexSpecialtyLens
    var history: [(role: String, content: String)] = []
    var truthMode: BrainTruthMode = .runtime
}

struct CortexBrainResponse: Sendable {
    let text: String
    let connected: Bool
}

enum CortexSuperBrainError: LocalizedError {
    case unavailable
    case unauthorized
    case server(Int)
    case parse
    case empty

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Super Brain route unavailable. Connect later when the backbone responds."
        case .unauthorized:
            return "Brain unavailable. Session could not be established."
        case .server(let code):
            return "Super Brain route unavailable (status \(code))."
        case .parse:
            return "Brain unavailable. Response could not be read."
        case .empty:
            return "Brain unavailable. Empty response."
        }
    }
}

/// Shared CORTEX Super Brain gateway — same relay pattern as Signal Zero CLI (`/v1/chat` + Bearer session).
final class CortexSuperBrainClient {
    static let shared = CortexSuperBrainClient()

    private let chatURL = "https://api.cortexnode.ai/v1/chat"
    private let healthURL = "https://api.cortexnode.ai/v1/cortex/health"

    private init() {}

    func probeConnection(lens: CortexSpecialtyLens) async -> BrainConnectionState {
        do {
            let token = try await AuthSessionStore.shared.validSessionToken()
            let ok = await validateHealth(token: token, lens: lens)
            return ok ? .connected : .error
        } catch {
            return .offline
        }
    }

    func complete(_ request: CortexBrainRequest) async throws -> CortexBrainResponse {
        let token = try await AuthSessionStore.shared.validSessionToken()
        let text = try await postChat(
            token: token,
            lens: request.lens,
            system: request.lens.systemPrompt,
            messages: buildMessages(history: request.history, prompt: request.prompt)
        )
        return CortexBrainResponse(text: text, connected: true)
    }

    func stream(_ request: CortexBrainRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await complete(request)
                    continuation.yield(response.text)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stream(prompt: String, lens: CortexSpecialtyLens) -> AsyncThrowingStream<String, Error> {
        stream(CortexBrainRequest(prompt: prompt, lens: lens))
    }

    // MARK: - Private

    private func buildMessages(history: [(role: String, content: String)], prompt: String) -> [[String: String]] {
        var payload = history.suffix(12).map { ["role": $0.role, "content": $0.content] }
        payload.append(["role": "user", "content": prompt])
        return payload
    }

    private func validateHealth(token: String, lens: CortexSpecialtyLens) async -> Bool {
        guard let url = URL(string: healthURL) else { return false }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(lens.surfaceHeader, forHTTPHeaderField: "x-cortex-surface")
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
        }
    }

    private func postChat(
        token: String,
        lens: CortexSpecialtyLens,
        system: String,
        messages: [[String: String]]
    ) async throws -> String {
        guard let url = URL(string: chatURL) else { throw CortexSuperBrainError.parse }

        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(lens.surfaceHeader, forHTTPHeaderField: "x-cortex-surface")

        let body: [String: Any] = [
            "model": "cortex-advanced",
            "max_tokens": 4096,
            "stream": false,
            "system": system,
            "messages": messages
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw CortexSuperBrainError.unavailable }

        if http.statusCode == 401 || http.statusCode == 403 {
            await AuthSessionStore.shared.clearSessionToken()
            throw CortexSuperBrainError.unauthorized
        }
        guard http.statusCode == 200 else { throw CortexSuperBrainError.server(http.statusCode) }

        return try parseRelayText(data)
    }

    private func parseRelayText(_ data: Data) throws -> String {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CortexSuperBrainError.parse
        }
        if let content = obj["content"] as? String, !content.isEmpty { return content }
        if let reply = obj["reply"] as? String, !reply.isEmpty { return reply }
        if let text = obj["text"] as? String, !text.isEmpty { return text }
        if let choices = obj["choices"] as? [[String: Any]],
           let msg = choices.first?["message"] as? [String: Any],
           let text = msg["content"] as? String, !text.isEmpty { return text }
        if let content = obj["content"] as? [[String: Any]] {
            let parts = content.compactMap { $0["text"] as? String }.filter { !$0.isEmpty }
            if !parts.isEmpty { return parts.joined(separator: "\n") }
        }
        throw CortexSuperBrainError.empty
    }
}
