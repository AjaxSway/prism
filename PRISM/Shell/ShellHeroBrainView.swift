import SwiftUI
import AVFoundation

// MARK: - Premium hero brain loop (shell V1 · mock-only · no fake live)

struct ShellHeroBrainConfig: Equatable {
    let resourceName: String
    let accent: Color
    let secondary: Color
    let label: String
    var gradeHue: Double = 0
    var gradeSaturation: Double = 1.15
    var gradeBrightness: Double = 0.02
    /// When false, always use SwiftUI animated core (PRISM draft studio — no dead mp4 loop).
    var useBundledVideo: Bool = true

    static let node = ShellHeroBrainConfig(
        resourceName: "node-core-brain-loop",
        accent: Color(red: 0, green: 0.82, blue: 0.96),
        secondary: Color(red: 0.05, green: 0.42, blue: 0.58),
        label: "NODE CORE",
        gradeHue: 0,
        gradeSaturation: 1.2
    )

    static let jericho = ShellHeroBrainConfig(
        resourceName: "jericho-core-brain-loop",
        accent: Color(red: 0.937, green: 0.267, blue: 0.267),
        secondary: Color(red: 0.2, green: 0.75, blue: 0.95),
        label: "JERICHO CORE",
        gradeHue: 350,
        gradeSaturation: 1.35
    )

    static let prism = ShellHeroBrainConfig(
        resourceName: "prism-core-brain-loop",
        accent: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
        secondary: Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255),
        label: "PRISM CORE",
        gradeHue: 280,
        gradeSaturation: 1.25,
        useBundledVideo: true
    )
}

struct ShellHeroBrainView: View {
    let config: ShellHeroBrainConfig
    var size: CGFloat = 280
    var orbState: ShellOrbState = .idle
    var subtitle: String = "PLATFORM PREVIEW · Requires setup"
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var glowShift = false

    private var hasVideo: Bool {
        config.useBundledVideo
            && Bundle.main.url(forResource: config.resourceName, withExtension: "mp4") != nil
    }

    private var stateAccent: Color {
        switch orbState {
        case .idle: return config.accent
        case .listening: return config.accent
        case .thinking: return Color(red: 0.42, green: 0.58, blue: 1.0)
        case .speaking: return Color(red: 0.55, green: 0.96, blue: 1.0)
        case .executing: return config.secondary
        case .success: return Color(red: 0.22, green: 0.78, blue: 0.45)
        case .warning: return Color(red: 0.98, green: 0.68, blue: 0.12)
        case .error: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .offline: return Color(red: 0.35, green: 0.38, blue: 0.42)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // Outer atmosphere
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                stateAccent.opacity(glowShift ? 0.28 : 0.16),
                                config.secondary.opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size * 1.18, height: size * 1.18)
                    .blur(radius: 18)
                    .scaleEffect(breathe ? 1.04 : 0.96)

                // Orbital rings — slow rotation, not frozen chrome
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [config.accent.opacity(0.45), config.secondary.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: i == 0 ? 1.6 : 0.8
                            )
                            .frame(width: size * (0.92 + CGFloat(i) * 0.08), height: size * (0.92 + CGFloat(i) * 0.08))
                            .opacity(0.35 + Double(i) * 0.12)
                            .rotationEffect(.degrees(t * (10 + Double(i) * 6) + Double(i) * 35))
                    }
                }

                heroCore
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [config.accent.opacity(0.7), config.secondary.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: stateAccent.opacity(0.45), radius: glowShift ? 28 : 16)
                    .scaleEffect(breathe ? 1.02 : 0.98)
            }
            .contentShape(Circle())
            .onTapGesture { onTap?() }

            VStack(spacing: 6) {
                Text("\(config.label) · \(orbState.label.uppercased())")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [stateAccent, config.secondary.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                    )
                    .tracking(1.2)
                Text(subtitle)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.42))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) { glowShift = true }
        }
    }

    @ViewBuilder
    private var heroCore: some View {
        if hasVideo {
            ShellHeroBrainLoopPlayer(resourceName: config.resourceName, config: config)
        } else if config.label == "PRISM CORE" {
            PrismHeroCoreView(config: config, orbState: orbState, size: size)
        } else {
            ShellHeroBrainFallback(config: config, orbState: orbState)
        }
    }
}

// MARK: - AVPlayer loop

private struct ShellHeroBrainLoopPlayer: UIViewRepresentable {
    let resourceName: String
    let config: ShellHeroBrainConfig

    func makeUIView(context: Context) -> ShellHeroBrainLoopUIView {
        let v = ShellHeroBrainLoopUIView(resourceName: resourceName, config: config)
        return v
    }

    func updateUIView(_ uiView: ShellHeroBrainLoopUIView, context: Context) {
        uiView.updateGrade(config)
    }
}

private final class ShellHeroBrainLoopUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var gradeView: UIView?

    init(resourceName: String, config: ShellHeroBrainConfig) {
        super.init(frame: .zero)
        backgroundColor = .clear
        setupPlayer(resourceName: resourceName)
        applyGrade(config)
    }

    required init?(coder: NSCoder) { fatalError() }

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { (layer as? AVPlayerLayer) ?? AVPlayerLayer() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playerLayer.cornerRadius = bounds.width / 2
        playerLayer.masksToBounds = true
        gradeView?.frame = bounds
    }

    func updateGrade(_ config: ShellHeroBrainConfig) {
        applyGrade(config)
    }

    private func setupPlayer(resourceName: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.isMuted = true
        queue.play()
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        player = queue
    }

    private func applyGrade(_ config: ShellHeroBrainConfig) {
        gradeView?.removeFromSuperview()
        let overlay = UIView(frame: bounds)
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = UIColor(config.accent.opacity(0.12))
        overlay.layer.compositingFilter = "overlayBlendMode"
        addSubview(overlay)
        gradeView = overlay
        playerLayer.opacity = Float(0.94)
    }
}

// MARK: - SwiftUI fallback (no bundled video)

private struct ShellHeroBrainFallback: View {
    let config: ShellHeroBrainConfig
    let orbState: ShellOrbState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.88 + 0.12 * sin(t * 1.4)
            ZStack {
                RadialGradient(
                    colors: [config.accent.opacity(0.5 * pulse), config.secondary.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 140
                )
                ShellAppCoreOrbView(
                    appKind: appKind,
                    color: config.accent,
                    secondary: config.secondary,
                    size: 200,
                    intensity: pulse,
                    orbState: orbState
                )
            }
        }
    }

    private var appKind: ShellAppKind {
        switch config.label {
        case "JERICHO CORE": return .jericho
        case "PRISM CORE": return .prism
        default: return .cortexNode
        }
    }
}
