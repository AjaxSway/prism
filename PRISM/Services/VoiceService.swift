import AVFoundation

// MARK: - VoiceService — ATLAS · ElevenLabs
// PRISM content intelligence responses are spoken by ATLAS (s3TPKV1kjDlVtZbl4Ksh).
// POST to ElevenLabs, play audio, silent on failure — no exceptions bubble up.

enum VoiceService {

    private static let apiKey  = "sk_3c730897851a71471f0524dc815c8af21a241ae79c72e00a"
    private static let voiceID = "s3TPKV1kjDlVtZbl4Ksh"   // ATLAS — Sir's active default
    private static let model   = "eleven_multilingual_v2"

    static func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Truncate to 500 chars — keeps latency short, covers any single reveal response
        let payload = String(trimmed.prefix(500))
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
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
            // Verify we got audio (ElevenLabs errors return JSON starting with '{')
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

    func play(_ data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("prism_voice_\(UUID().uuidString).mp3")
        do {
            try data.write(to: tmp)
            player = try AVAudioPlayer(contentsOf: tmp)
            player?.delegate = self
            player?.play()
        } catch {}
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
