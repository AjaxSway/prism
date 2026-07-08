import AVFoundation
import SwiftUI
import UIKit

/// God Mode intro player — black hold until first frame, aspect-fill, single play.
struct ShellIntroVideoPlayer: UIViewRepresentable {
    let videoName: String
    let onReady: () -> Void
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady, onFinish: onFinish)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            DispatchQueue.main.async { context.coordinator.callFinish() }
            return view
        }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = UIColor.black.cgColor
        view.layer.addSublayer(layer)

        context.coordinator.player = player
        context.coordinator.playerLayer = layer

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        context.coordinator.statusObserver = item.observe(\.status, options: [.new]) { [weak c = context.coordinator] item, _ in
            guard let c else { return }
            switch item.status {
            case .readyToPlay:
                c.player?.play()
                DispatchQueue.main.async { c.callReady() }
            case .failed:
                DispatchQueue.main.async { c.callFinish() }
            default:
                break
            }
        }

        context.coordinator.scheduleFailsafe()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.playerLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.statusObserver?.invalidate()
        coordinator.statusObserver = nil
        coordinator.cancelFailsafe()
        NotificationCenter.default.removeObserver(coordinator)
    }

    final class Coordinator: NSObject {
        let onReady: () -> Void
        let onFinish: () -> Void
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var statusObserver: NSKeyValueObservation?
        private var failsafeTimer: Timer?
        private var finished = false
        private var readyCalled = false

        init(onReady: @escaping () -> Void, onFinish: @escaping () -> Void) {
            self.onReady = onReady
            self.onFinish = onFinish
        }

        func callReady() {
            guard !readyCalled else { return }
            readyCalled = true
            onReady()
        }

        func callFinish() {
            guard !finished else { return }
            finished = true
            cancelFailsafe()
            player?.pause()
            DispatchQueue.main.async { self.onFinish() }
        }

        @objc func playerDidFinish() { callFinish() }

        func scheduleFailsafe() {
            cancelFailsafe()
            failsafeTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
                self?.callFinish()
            }
        }

        func cancelFailsafe() {
            failsafeTimer?.invalidate()
            failsafeTimer = nil
        }
    }
}
