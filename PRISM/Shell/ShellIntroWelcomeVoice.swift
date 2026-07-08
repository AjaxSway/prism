import AVFoundation
import Foundation

/// Adam welcome clip — plays once over intro video (all apps except CORTEX Babies).
@MainActor
final class ShellIntroWelcomeVoice {
    static let shared = ShellIntroWelcomeVoice()

    private var player: AVAudioPlayer?
    private(set) var isPlaying = false

    private init() {}

    func play() {
        stop()
        guard let url = Bundle.main.url(forResource: "cortex_intro_greeting", withExtension: "mp3") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.volume = 1.0
            audio.prepareToPlay()
            player = audio
            isPlaying = true
            audio.play()
            let duration = audio.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.15) { [weak self] in
                self?.isPlaying = false
            }
        } catch {
            player = nil
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
