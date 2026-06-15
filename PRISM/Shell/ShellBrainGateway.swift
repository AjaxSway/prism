import Foundation

/// Single integration point for Claude to flip live brain routing.
/// Set `ShellFeatureFlags.brainConnected = true` after backend + auth verified.
@MainActor
@Observable
final class ShellBrainGateway {
    static let shared = ShellBrainGateway()

    enum ConnectionState: String, Sendable {
        case offline = "Not connected"
        case preview = "Shell preview"
        case connecting = "Connecting"
        case connected = "Connected"
        case error = "Error"
    }

    private(set) var state: ConnectionState = .preview
    private(set) var statusDetail = "Mock preview · Set brainConnected when wiring live."
    private(set) var lastError: String?

    var isLive: Bool {
        ShellFeatureFlags.brainConnected && state == .connected
    }

    private init() {
        refreshState()
    }

    func refreshState() {
        if !ShellFeatureFlags.brainConnected {
            state = .preview
            statusDetail = "Shell preview · Claude wires BrainConnector next."
            return
        }
        state = .offline
        statusDetail = "Tap Connect to reach api.cortexnode.ai."
    }

    func connect(appKind: ShellAppKind) async {
        guard ShellFeatureFlags.brainConnected else {
            refreshState()
            return
        }
        state = .connecting
        statusDetail = "Establishing session…"
        lastError = nil
        do {
            _ = try await AuthSessionStore.shared.validSessionToken()
            state = .connected
            statusDetail = "CORTEX backbone reachable · \(appKindLabel(appKind))"
        } catch {
            state = .error
            lastError = error.localizedDescription
            statusDetail = lastError ?? "Connection failed."
        }
    }

    func disconnect() {
        Task {
            await AuthSessionStore.shared.clearSessionToken()
            refreshState()
        }
    }

    /// Text command / chat — routes to app BrainConnector when live.
    func stream(prompt: String, appKind: ShellAppKind) async -> AsyncThrowingStream<String, Error> {
        guard ShellFeatureFlags.brainConnected, state == .connected else {
            return mockStream(prompt: prompt, appKind: appKind)
        }
        return await BrainConnector.shared.shellStream(prompt: prompt)
    }

    private func mockStream(prompt: String, appKind: ShellAppKind) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                continuation.yield("[Preview] \(appKindLabel(appKind)) received: \(prompt.prefix(120))… Connect brain for live response.")
                continuation.finish()
            }
        }
    }

    private func appKindLabel(_ kind: ShellAppKind) -> String {
        switch kind {
        case .cortexNode: return "CORTEXNODE"
        case .jericho: return "JERICHO"
        case .prism: return "PRISM"
        }
    }
}

/// PRISM image generation — Claude implements against api.cortexnode.ai or Bedrock route.
protocol ShellImageGenerationServing: Sendable {
    func generate(prompt: String, preset: String, style: String) async throws -> Data
}

struct ShellPreviewImageGenerationService: ShellImageGenerationServing {
    func generate(prompt: String, preset: String, style: String) async throws -> Data {
        throw ShellBrainWireError.previewOnly
    }
}

enum ShellBrainWireError: LocalizedError {
    case previewOnly
    case notConnected

    var errorDescription: String? {
        switch self {
        case .previewOnly: return "Image generation requires brain connection."
        case .notConnected: return "Connect to CORTEX backbone first."
        }
    }
}
