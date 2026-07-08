import Foundation

/// Single integration point for CORTEX Super Brain routing (Signal Zero CLI relay pattern).
@MainActor
@Observable
final class ShellBrainGateway {
    static let shared = ShellBrainGateway()

    enum ConnectionState: String, Sendable {
        case offline = "Not connected"
        case preview = "Shell preview"
        case connecting = "Connecting"
        case connected = "Brain connected"
        case error = "Super Brain route unavailable"
    }

    private(set) var state: ConnectionState = .preview
    private(set) var statusDetail = "Super Brain route · first prompt establishes session."
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
            statusDetail = "Shell preview · Super Brain route requires setup."
            return
        }
        state = .offline
        statusDetail = "Super Brain enabled · first prompt establishes session."
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
            statusDetail = "Brain connected · \(appKindLabel(appKind)) lens"
        } catch {
            state = .error
            lastError = sanitized(error)
            statusDetail = lastError ?? "Super Brain route unavailable."
        }
    }

    func disconnect() {
        Task {
            await AuthSessionStore.shared.clearSessionToken()
            refreshState()
        }
    }

    /// Text command / chat — routes through CortexSuperBrainClient with app specialty lens.
    func stream(prompt: String, appKind: ShellAppKind) async -> AsyncThrowingStream<String, Error> {
        guard ShellFeatureFlags.brainConnected else {
            return unavailableStream("Shell preview · Super Brain route disabled for this build.")
        }

        let lens = CortexSpecialtyLens(shellAppKind: appKind)
        state = .connecting
        statusDetail = "Routing through Super Brain · \(appKindLabel(appKind)) lens…"

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var full = ""
                    for try await chunk in CortexSuperBrainClient.shared.stream(prompt: prompt, lens: lens) {
                        full += chunk
                        continuation.yield(chunk)
                    }
                    guard !full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw CortexSuperBrainError.empty
                    }
                    state = .connected
                    statusDetail = "Brain connected · \(appKindLabel(appKind)) lens"
                    continuation.finish()
                } catch {
                    state = .error
                    lastError = sanitized(error)
                    statusDetail = lastError ?? "Super Brain route unavailable."
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func markError(_ message: String) {
        state = .error
        lastError = sanitizedMessage(message)
        statusDetail = lastError ?? "Super Brain route unavailable."
    }

    private func sanitizedMessage(_ message: String) -> String {
        if message.lowercased().contains("token") || message.lowercased().contains("bearer") {
            return "Brain unavailable. Session could not be established."
        }
        return message
    }

    private func unavailableStream(_ message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                state = .preview
                statusDetail = message
                continuation.yield(message)
                continuation.finish()
            }
        }
    }

    private func sanitized(_ error: Error) -> String {
        let raw = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if raw.lowercased().contains("token") || raw.lowercased().contains("bearer") {
            return "Brain unavailable. Session could not be established."
        }
        return raw
    }

    private func appKindLabel(_ kind: ShellAppKind) -> String {
        switch kind {
        case .cortexNode: return "CORTEXNODE"
        case .jericho: return "JERICHO"
        case .prism: return "PRISM"
        }
    }
}

/// PRISM image generation — routes when brain connected.
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
        case .notConnected: return "Super Brain route unavailable."
        }
    }
}
