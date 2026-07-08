import Foundation

/// User-controlled voice playback for shell brain responses — off by default.
@MainActor
@Observable
final class ShellVoicePreferences {
    static let shared = ShellVoicePreferences()

    private let enabledKey = "prism.shell.voice.speakResponses"

    var speakResponsesEnabled: Bool {
        didSet { UserDefaults.standard.set(speakResponsesEnabled, forKey: enabledKey) }
    }

    private(set) var lastPlaybackStatus: String = "Voice unavailable until you tap Hear Response"

    private init() {
        speakResponsesEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    func markAttempted() {
        lastPlaybackStatus = "Voice route requested · api.cortexnode.ai/v1/voice/speak"
    }

    func markSucceeded() {
        lastPlaybackStatus = "Voice playback started · session route"
    }

    func markUnavailable() {
        lastPlaybackStatus = "Voice unavailable · Super Brain session required · Connect later"
    }
}
