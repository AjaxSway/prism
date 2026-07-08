import SwiftUI
import AVFoundation
import UIKit

// MARK: - State (truth-based — never fake LIVE)

enum CortexBrainPulseState: Equatable {
    case idle
    case checking
    case ready
    case listening
    case thinking
    case responding
    case speaking
    case degraded
    case offline
    case error

    var isActive: Bool {
        switch self {
        case .listening, .thinking, .responding, .speaking: return true
        case .idle, .checking, .ready, .degraded, .offline, .error: return false
        }
    }

    var isDegraded: Bool {
        switch self {
        case .degraded, .offline, .error: return true
        default: return false
        }
    }

    /// Maps core health proof to pulse — never fakes LIVE/ACTIVE.
    static func fromHealthCheck(
        checkedAt: Date,
        coreReady: Bool,
        chatReady: Bool,
        apiOK: Bool,
        activityOverride: CortexBrainPulseState? = nil
    ) -> CortexBrainPulseState {
        if let activityOverride, activityOverride.isActive { return activityOverride }
        if checkedAt == .distantPast { return .checking }
        if !apiOK { return .offline }
        if coreReady { return activityOverride ?? .ready }
        if chatReady { return .degraded }
        return .error
    }
}

// MARK: - Per-app color themes

enum CortexBrainPulseApp: String, CaseIterable {
    case cortex, cortexnode, prism, atlas, forge, jericho, signalZero

    var theme: CortexBrainPulseTheme {
        switch self {
        case .cortex:
            return CortexBrainPulseTheme(
                primary: Color(red: 1.0, green: 0.18, blue: 0.55),
                secondary: Color(red: 0.0, green: 0.83, blue: 1.0),
                app: self
            )
        case .cortexnode:
            return CortexBrainPulseTheme(
                primary: Color(red: 0.0, green: 0.83, blue: 1.0),
                secondary: Color(red: 0.0, green: 0.65, blue: 0.72),
                app: self
            )
        case .prism:
            return CortexBrainPulseTheme(
                primary: Color(red: 0.62, green: 0.35, blue: 1.0),
                secondary: Color(red: 0.82, green: 0.55, blue: 1.0),
                app: self
            )
        case .atlas:
            return CortexBrainPulseTheme(
                primary: Color(red: 0.0, green: 0.72, blue: 1.0),
                secondary: Color(red: 0.2, green: 0.55, blue: 0.95),
                app: self
            )
        case .forge:
            return CortexBrainPulseTheme(
                primary: Color(red: 1.0, green: 0.55, blue: 0.12),
                secondary: Color(red: 1.0, green: 0.75, blue: 0.25),
                app: self
            )
        case .jericho:
            return CortexBrainPulseTheme(
                primary: Color(red: 0.95, green: 0.22, blue: 0.22),
                secondary: Color(red: 0.15, green: 0.85, blue: 0.45),
                app: self
            )
        case .signalZero:
            return CortexBrainPulseTheme(
                primary: Color(red: 0.0, green: 0.92, blue: 1.0),
                secondary: Color.white.opacity(0.85),
                app: self
            )
        }
    }
}

struct CortexBrainPulseTheme {
    let primary: Color
    let secondary: Color
    let app: CortexBrainPulseApp

    static let cortex = CortexBrainPulseApp.cortex.theme
    static let cortexnode = CortexBrainPulseApp.cortexnode.theme
    static let prism = CortexBrainPulseApp.prism.theme
    static let atlas = CortexBrainPulseApp.atlas.theme
    static let forge = CortexBrainPulseApp.forge.theme
    static let jericho = CortexBrainPulseApp.jericho.theme
    static let signalZero = CortexBrainPulseApp.signalZero.theme
}

// MARK: - Shared view

struct SharedCortexBrainPulseView: View {
    let state: CortexBrainPulseState
    let theme: CortexBrainPulseTheme
    var size: CGFloat = 120
    var useVideoBackground: Bool = false
    var videoResourceName: String? = "cortex_brain_loop"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.35
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var particlePhase: Double = 0

    private var pulseColor: Color {
        if state.isDegraded { return theme.primary.opacity(0.35) }
        return theme.primary
    }

    var body: some View {
        ZStack {
            radialGlow
            outerRing
            innerRing
            coreContent
            stateGlyph
        }
        .frame(width: size, height: size)
        .onAppear {
            startRotationsIfAllowed()
            applyAnimation(for: state)
        }
        .onChange(of: state) { _, newState in
            applyAnimation(for: newState)
        }
        .onChange(of: reduceMotion) { _, _ in
            startRotationsIfAllowed()
            applyAnimation(for: state)
        }
    }

    @ViewBuilder
    private var coreContent: some View {
        if useVideoBackground,
           let name = videoResourceName,
           Bundle.main.url(forResource: name, withExtension: "mp4") != nil {
            CortexBrainPulseVideoView(resourceName: name)
                .frame(width: size * 0.72, height: size * 0.72)
                .clipShape(Circle())
                .opacity(state.isDegraded ? 0.25 : 0.92)
                .scaleEffect(pulseScale * 0.99)
        } else {
            swiftUIFallbackCore
        }
    }

    private var swiftUIFallbackCore: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.secondary.opacity(state.isDegraded ? 0.08 : glowOpacity * 0.9),
                            theme.primary.opacity(state.isDegraded ? 0.05 : glowOpacity * 0.45),
                            .clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.34
                    )
                )
                .frame(width: size * 0.62, height: size * 0.62)
                .blur(radius: 6)

            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(theme.secondary.opacity(state.isDegraded ? 0.15 : 0.55))
                    .frame(width: 3, height: 3)
                    .offset(y: -(size * 0.22))
                    .rotationEffect(.degrees(particlePhase + Double(i) * 45))
            }

            Image(systemName: "brain.head.profile")
                .font(.system(size: size * 0.22, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.secondary, theme.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(state.isDegraded ? 0.35 : 0.85)
                .shadow(color: theme.primary.opacity(glowOpacity), radius: 10)
        }
        .scaleEffect(pulseScale)
    }

    private var radialGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        pulseColor.opacity(state.isDegraded ? 0.04 : glowOpacity * 0.35),
                        pulseColor.opacity(state.isDegraded ? 0.02 : glowOpacity * 0.12),
                        .clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: size * 0.62
                )
            )
            .frame(width: size * 1.25, height: size * 1.25)
            .blur(radius: size * 0.12)
            .scaleEffect(pulseScale * 1.08)
    }

    private var outerRing: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        pulseColor.opacity(state.isDegraded ? 0.12 : 0.35),
                        pulseColor.opacity(0.05),
                        theme.secondary.opacity(state.isDegraded ? 0.08 : 0.25),
                        pulseColor.opacity(0.05),
                        pulseColor.opacity(state.isDegraded ? 0.12 : 0.35)
                    ],
                    center: .center
                ),
                lineWidth: state.isActive ? 1.5 : 1
            )
            .frame(width: size * 1.05, height: size * 1.05)
            .rotationEffect(.degrees(outerRotation))
            .opacity(state.isDegraded ? 0.4 : 1)
    }

    private var innerRing: some View {
        Circle()
            .stroke(
                pulseColor.opacity(state.isDegraded ? 0.1 : 0.22),
                style: StrokeStyle(lineWidth: 1, dash: [6, 5])
            )
            .frame(width: size * 0.88, height: size * 0.88)
            .rotationEffect(.degrees(innerRotation))
    }

    @ViewBuilder
    private var stateGlyph: some View {
        switch state {
        case .listening:
            Image(systemName: "waveform")
                .font(.system(size: size * 0.09, weight: .bold))
                .foregroundStyle(theme.secondary)
                .offset(y: -(size * 0.42))
        case .speaking, .responding:
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size * 0.09, weight: .bold))
                .foregroundStyle(theme.primary)
                .offset(y: -(size * 0.42))
        case .offline, .error, .degraded:
            Image(systemName: glyphName(for: state))
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(theme.primary.opacity(0.5))
                .offset(y: -(size * 0.42))
        case .checking:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(theme.secondary.opacity(0.65))
                .offset(y: -(size * 0.42))
        default:
            EmptyView()
        }
    }

    private func glyphName(for state: CortexBrainPulseState) -> String {
        switch state {
        case .offline: return "wifi.slash"
        case .degraded: return "exclamationmark.triangle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func startRotationsIfAllowed() {
        guard !reduceMotion else {
            outerRotation = 0
            innerRotation = 0
            particlePhase = 0
            return
        }
        withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }
        withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) {
            particlePhase = 360
        }
    }

    private func applyAnimation(for state: CortexBrainPulseState) {
        guard !reduceMotion else {
            switch state {
            case .speaking, .responding:
                pulseScale = 1.05
                glowOpacity = 0.9
            case .thinking:
                pulseScale = 1.04
                glowOpacity = 0.75
            case .listening:
                pulseScale = 1.03
                glowOpacity = 0.65
            case .checking:
                pulseScale = 1.01
                glowOpacity = 0.28
            case .ready:
                pulseScale = 1.02
                glowOpacity = 0.45
            case .degraded, .offline, .error:
                pulseScale = 1.0
                glowOpacity = 0.15
            case .idle:
                pulseScale = 1.0
                glowOpacity = 0.35
            }
            return
        }

        switch state {
        case .speaking, .responding:
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                glowOpacity = 1.0
            }
        case .thinking:
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
                glowOpacity = 0.85
            }
        case .listening:
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
                glowOpacity = 0.7
            }
        case .checking:
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.015
                glowOpacity = 0.3
            }
        case .ready:
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.025
                glowOpacity = 0.48
            }
        case .degraded, .offline, .error:
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.0
                glowOpacity = 0.15
            }
        case .idle:
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.02
                glowOpacity = 0.4
            }
        }
    }
}

// MARK: - Optional bundled video (hardware decode)

private struct CortexBrainPulseVideoView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> CortexBrainPulseVideoUIView {
        CortexBrainPulseVideoUIView(resourceName: resourceName)
    }

    func updateUIView(_ uiView: CortexBrainPulseVideoUIView, context: Context) {}
}

private final class CortexBrainPulseVideoUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    init(resourceName: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
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

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        player?.pause()
    }
}
