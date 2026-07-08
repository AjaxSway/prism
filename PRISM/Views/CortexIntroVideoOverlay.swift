import AVFoundation
import SwiftUI
import UIKit

/// Video speaks first on black · poster fades in under screen-blend loop (CORTEX canon).
struct CortexIntroHeroStack: View {
    let imageName: String
    var videoResourceName: String?
    var fitMode: Bool = false
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var verticalNudge: CGFloat = 0.02
    var posterDownshift: CGFloat = 18
    var showVideoOverlay: Bool = true
    var videoBlendMode: BlendMode = .screen

    var body: some View {
        CortexIntroCompositeView(
            imageName: imageName,
            videoResourceName: videoResourceName,
            showVideoOverlay: showVideoOverlay,
            posterDownshift: posterDownshift
        )
        .ignoresSafeArea()
    }
}

// MARK: - UIKit composite

struct CortexIntroCompositeView: UIViewRepresentable {
    let imageName: String
    var videoResourceName: String?
    var showVideoOverlay: Bool
    var posterDownshift: CGFloat = 18

    func makeUIView(context: Context) -> CortexIntroCompositeUIView {
        let view = CortexIntroCompositeUIView()
        view.configure(
            imageName: imageName,
            videoResourceName: videoResourceName,
            showVideo: showVideoOverlay,
            posterDownshift: posterDownshift
        )
        return view
    }

    func updateUIView(_ uiView: CortexIntroCompositeUIView, context: Context) {
        uiView.configure(
            imageName: imageName,
            videoResourceName: videoResourceName,
            showVideo: showVideoOverlay,
            posterDownshift: posterDownshift
        )
    }

    static func dismantleUIView(_ uiView: CortexIntroCompositeUIView, coordinator: ()) {
        uiView.stop()
    }
}

final class CortexIntroCompositeUIView: UIView {
    private let posterView = UIImageView()
    private let videoHost = UIView()
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var statusObservation: NSKeyValueObservation?
    private var configuredVideoName: String?
    private var posterDownshift: CGFloat = 18
    private var configuredImageName: String?
    private var posterRevealWorkItem: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = false
        posterView.isOpaque = true
        posterView.alpha = 0
        addSubview(posterView)

        videoHost.backgroundColor = .clear
        videoHost.isOpaque = false
        videoHost.clipsToBounds = true
        addSubview(videoHost)

        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.clear.cgColor
        playerLayer.compositingFilter = "screenBlendMode"
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.opacity = 0
        videoHost.layer.addSublayer(playerLayer)

        registerLifecycleObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = mediaFrame(in: bounds)
        posterView.frame = frame
        videoHost.frame = bounds
        playerLayer.frame = videoHost.bounds
    }

    func configure(imageName: String, videoResourceName: String?, showVideo: Bool, posterDownshift: CGFloat) {
        self.posterDownshift = posterDownshift

        if configuredImageName != imageName {
            posterView.image = UIImage(named: imageName)
            configuredImageName = imageName
            setNeedsLayout()
        }

        videoHost.isHidden = !showVideo

        guard showVideo, let videoResourceName else {
            player?.pause()
            playerLayer.opacity = 0
            posterView.alpha = 1
            return
        }

        guard configuredVideoName != videoResourceName else {
            if player?.timeControlStatus != .playing, playerLayer.opacity > 0 {
                player?.play()
            }
            return
        }

        stopPlayback()

        guard let url = Bundle.main.url(forResource: videoResourceName, withExtension: "mp4") else {
            posterView.alpha = 1
            return
        }

        posterView.alpha = 0
        playerLayer.opacity = 0

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2

        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.automaticallyWaitsToMinimizeStalling = true

        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        playerLayer.player = queuePlayer
        player = queuePlayer
        configuredVideoName = videoResourceName

        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.configuredVideoName == videoResourceName else { return }
                switch item.status {
                case .readyToPlay:
                    queuePlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    queuePlayer.play()
                    // VIDEO FIRST — speaking loop on black
                    self.playerLayer.opacity = 1
                    self.posterView.alpha = 0
                    self.schedulePosterReveal(for: videoResourceName)
                case .failed:
                    self.playerLayer.opacity = 0
                    self.posterView.alpha = 1
                default:
                    self.playerLayer.opacity = 0
                    self.posterView.alpha = 0
                }
            }
        }
    }

    func stop() {
        stopPlayback()
    }

    private func schedulePosterReveal(for videoResourceName: String) {
        posterRevealWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.configuredVideoName == videoResourceName else { return }
            UIView.animate(withDuration: 0.55) {
                self.posterView.alpha = 1
            }
        }
        posterRevealWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: work)
    }

    private func stopPlayback() {
        posterRevealWorkItem?.cancel()
        posterRevealWorkItem = nil
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        player = nil
        looper = nil
        playerLayer.player = nil
        playerLayer.opacity = 0
        configuredVideoName = nil
    }

    private func resolvedSafeAreaTop() -> CGFloat {
        if let inset = window?.safeAreaInsets.top, inset > 0 { return inset }
        return 59
    }

    /// Shift poster down so embedded title clears Dynamic Island; extend fill upward so no black bar.
    private func mediaFrame(in bounds: CGRect) -> CGRect {
        let topInset = resolvedSafeAreaTop()
        let titleClearance = topInset + posterDownshift

        guard let image = posterView.image, image.size.width > 0, image.size.height > 0 else {
            return bounds
        }

        let imageAspect = image.size.width / image.size.height
        let viewAspect = bounds.width / bounds.height

        var fillWidth: CGFloat
        var fillHeight: CGFloat

        if imageAspect > viewAspect {
            fillHeight = bounds.height + titleClearance
            fillWidth = fillHeight * imageAspect
        } else {
            fillWidth = bounds.width
            fillHeight = fillWidth / imageAspect
            let minimumHeight = bounds.height + titleClearance
            if fillHeight < minimumHeight {
                fillHeight = minimumHeight
                fillWidth = fillHeight * imageAspect
            }
        }

        let originX = (bounds.width - fillWidth) / 2
        let originY = titleClearance - titleClearance * 0.12
        return CGRect(x: originX, y: originY, width: fillWidth, height: fillHeight)
    }

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default
        lifecycleObservers.append(
            center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                if self?.playerLayer.opacity ?? 0 > 0 { self?.player?.play() }
            }
        )
        lifecycleObservers.append(
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                if self?.playerLayer.opacity ?? 0 > 0 { self?.player?.play() }
            }
        )
    }

    deinit {
        for token in lifecycleObservers {
            NotificationCenter.default.removeObserver(token)
        }
        stopPlayback()
    }
}
