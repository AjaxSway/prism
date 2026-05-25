import AVFoundation

// MARK: - VoiceService — PRISM Spoken Responses
// Routes through api.cortexnode.ai/v1/voice/speak — voice ID configured server-side.
// Silent on failure — voice is enhancement, not core functionality.

enum VoiceService {

    private static let serverEndpoint = "https://api.cortexnode.ai/v1/voice/speak"
    private static let model = "eleven_multilingual_v2"

    static func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let payload = String(trimmed.prefix(500))
        guard let url = URL(string: serverEndpoint) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "text": payload,
            "model_id": model,
            "voice_settings": [
                "stability": 0.75,
                "similarity_boost": 0.85,
                "style": 0.35,
                "use_speaker_boost": true
            ]
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        req.httpBody = httpBody
        URLSession.shared.dataTask(with: req) { data, response, _ in
            guard let data, !data.isEmpty else { return }
            if let first = data.first, first == 0x7B { return }
            DispatchQueue.main.async {
                PRISMAudioPlayer.shared.play(data)
            }
        }.resume()
    }
}

// MARK: - Audio Player

private final class PRISMAudioPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = PRISMAudioPlayer()
    private var player: AVAudioPlayer?
    private var currentTempURL: URL?

    func play(_ data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("prism_voice_\(UUID().uuidString).mp3")
        do {
            try data.write(to: tmp)
            currentTempURL = tmp
            player = try AVAudioPlayer(contentsOf: tmp)
            player?.delegate = self
            player?.play()
        } catch {
            try? FileManager.default.removeItem(at: tmp)
            currentTempURL = nil
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if let url = currentTempURL {
            try? FileManager.default.removeItem(at: url)
            currentTempURL = nil
        }
    }
}
