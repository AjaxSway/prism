import AVFoundation
import Foundation
import Observation

/// CORTEX `cortex-theme.mp3` — loops on physical device only. Simulator stays silent (Mac speaker static).
@MainActor
@Observable
final class ShellIntroMusic {
    static let shared = ShellIntroMusic()

    /// True on iOS Simulator — never route theme audio to Mac speakers.
    static var isRunningOnSimulator: Bool {
        if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
            return true
        }
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.environment["SIMULATOR_UDID"] != nil
        #endif
    }

    static let enabledStorageKey = "cortex.shell.backgroundMusic"
    static let legacyEnabledStorageKey = "aurion.shell.backgroundMusic"

    private static let legacyIntroKeys = [
        "aurion.shell.backgroundMusic",
        "forge.introMusicEnabled",
        "atlas.introMusicEnabled",
        "sz.introMusicEnabled",
        "cortex.babies.introMusicEnabled",
    ]

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            if Self.isRunningOnSimulator {
                if isEnabled { isEnabled = false }
                stopImmediately()
                return
            }
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledStorageKey)
            if isEnabled, !shouldSuppressPlayback {
                ensurePlaying()
            } else {
                fadeOutAndStop()
            }
        }
    }

    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var interruptionObserver: NSObjectProtocol?
    private let defaultVolume: Float = 0.72

    private init() {
        let defaults = UserDefaults.standard
        if Self.isRunningOnSimulator {
            isEnabled = false
            registerInterruptionHandler()
            return
        }
        if defaults.object(forKey: Self.enabledStorageKey) == nil {
            if let legacyKey = Self.legacyIntroKeys.first(where: { defaults.object(forKey: $0) != nil }) {
                isEnabled = defaults.bool(forKey: legacyKey)
                defaults.set(isEnabled, forKey: Self.enabledStorageKey)
            } else {
                isEnabled = true
            }
        } else {
            isEnabled = defaults.bool(forKey: Self.enabledStorageKey)
        }
        registerInterruptionHandler()
    }

    private var shouldSuppressPlayback: Bool {
        if Self.isRunningOnSimulator { return true }
        if ProcessInfo.processInfo.environment["PRISM_DISABLE_MUSIC"] == "1" { return true }
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiTestSkipIntro") || args.contains("-suppressBackgroundMusic") {
            return true
        }
        return false
    }

    func playIfAvailable() {
        guard !shouldSuppressPlayback else {
            stopImmediately()
            return
        }
        guard isEnabled else { return }
        ensurePlaying()
    }

    func ensurePlaying() {
        guard !shouldSuppressPlayback else {
            stopImmediately()
            return
        }
        guard isEnabled else { return }

        activateSessionIfNeeded()

        if let player {
            if !player.isPlaying {
                player.volume = defaultVolume
                player.play()
            }
            return
        }

        guard let url = Bundle.main.url(forResource: "cortex-theme", withExtension: "mp3") else { return }

        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.numberOfLoops = -1
            audio.volume = defaultVolume
            audio.prepareToPlay()
            audio.play()
            player = audio
        } catch {
            player = nil
        }
    }

    func fadeOutAndStop(duration: TimeInterval = 0.55) {
        fadeTimer?.invalidate()
        fadeTimer = nil
        guard let player else { return }

        let steps = 10
        let interval = duration / Double(steps)
        let startVolume = player.volume

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, let player = self.player else {
                    timer.invalidate()
                    return
                }
                player.volume = max(0, player.volume - startVolume / Float(steps))
                if player.volume <= 0.02 {
                    timer.invalidate()
                    self.fadeTimer = nil
                    player.stop()
                    self.player = nil
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                }
            }
        }
    }

    func stopImmediately() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        let hadPlayer = player != nil
        player?.stop()
        player = nil
        if hadPlayer || Self.isRunningOnSimulator {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func activateSessionIfNeeded() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Keep trying on next ensurePlaying call.
        }
    }

    private func registerInterruptionHandler() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let typeValue = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            if type == .ended, !Self.isRunningOnSimulator {
                self.playIfAvailable()
            }
        }
    }
}
