import Foundation
import AVFoundation

// MARK: - VoiceService — PRISM Spoken Responses
// Routes through api.cortexnode.ai/v1/voice/speak — voice ID configured server-side.
// Serializes playback — never stacks overlapping clips (prevents garble/static).

final class VoiceService: NSObject {
    static let shared = VoiceService()

    private let serverEndpoint = "https://api.cortexnode.ai/v1/voice/speak"
    private let authSession = AuthSessionStore.shared

    private var player: AVAudioPlayer?
    private var currentTmpURL: URL?
    private var speakTask: Task<Void, Never>?

    private override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers]
            )
            try session.setActive(true)
        } catch {}
    }

    static func speak(_ text: String) {
        shared.speak(text)
    }

    /// User-triggered playback with honest status for Settings UI.
    @MainActor
    static func speakWithStatus(_ text: String) async -> Bool {
        await shared.speakWithStatus(text)
    }

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        speakTask?.cancel()
        speakTask = Task { await speakInternal(String(trimmed.prefix(500))) }
    }

    func speak(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await speakInternal(String(trimmed.prefix(500)))
    }

    @MainActor
    func speakWithStatus(_ text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        ShellVoicePreferences.shared.markAttempted()
        speakTask?.cancel()
        await speakInternal(String(trimmed.prefix(500)))
        return ShellVoicePreferences.shared.lastPlaybackStatus.contains("started")
    }

    private func speakInternal(_ text: String) async {
        guard !Task.isCancelled else { return }
        guard let url = URL(string: serverEndpoint) else {
            await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
            return
        }
        guard let token = try? await authSession.validSessionToken() else {
            await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: ["text": text]) else {
            await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
            return
        }
        req.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard !Task.isCancelled else { return }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
                return
            }
            guard Self.isLikelyAudio(data) else {
                await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
                return
            }
            await MainActor.run {
                ShellVoicePreferences.shared.markSucceeded()
                playAudio(data)
            }
        } catch {
            await MainActor.run { ShellVoicePreferences.shared.markUnavailable() }
        }
    }

    @MainActor
    private func playAudio(_ data: Data) {
        stopCurrentPlayback()
        configureSession()

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("prism_voice_\(UUID().uuidString).mp3")
        do {
            try data.write(to: tmp)
            currentTmpURL = tmp
            player = try AVAudioPlayer(contentsOf: tmp)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            try? FileManager.default.removeItem(at: tmp)
            currentTmpURL = nil
        }
    }

    @MainActor
    private func stopCurrentPlayback() {
        player?.stop()
        player = nil
        cleanupTmpFile()
    }

    @MainActor
    private func cleanupTmpFile() {
        if let url = currentTmpURL {
            try? FileManager.default.removeItem(at: url)
            currentTmpURL = nil
        }
    }

    private static func isLikelyAudio(_ data: Data) -> Bool {
        guard data.count > 1024, let first = data.first else { return false }
        return first != 0x7B
    }
}

extension VoiceService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.cleanupTmpFile()
            self.player = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.cleanupTmpFile()
            self.player = nil
        }
    }
}
