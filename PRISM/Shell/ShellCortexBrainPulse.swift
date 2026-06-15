import SwiftUI

/// CORTEX-inspired brain pulse — TimelineView motion, voice-state reactive. Shell-local only.
enum ShellBrainPulseVisual: Equatable {
    case idle
    case active
    case dim

    static func from(orbState: ShellOrbState) -> ShellBrainPulseVisual {
        switch orbState {
        case .listening, .thinking, .speaking, .executing:
            return .active
        case .offline:
            return .dim
        default:
            return .idle
        }
    }
}

enum ShellBrainPulseMotion {
    struct Sample {
        var scale: CGFloat
        var coreOpacity: Double
        var ringOpacity: Double
    }

    static func phase(for visual: ShellBrainPulseVisual, date: Date) -> Sample {
        let t = date.timeIntervalSinceReferenceDate
        let freq: Double
        let amp: CGFloat
        let ring: Double
        switch visual {
        case .idle:
            freq = 0.28
            amp = 0.03
            ring = 0.35
        case .active:
            freq = 1.0
            amp = 0.09
            ring = 0.72
        case .dim:
            freq = 0.12
            amp = 0.01
            ring = 0.12
        }
        let wave = sin(t * freq * 2 * .pi)
        let scale = 1.0 + amp * CGFloat(wave)
        let core = 0.55 + 0.35 * (wave + 1) / 2
        return Sample(
            scale: scale,
            coreOpacity: visual == .dim ? 0.35 : core,
            ringOpacity: ring
        )
    }
}

struct ShellCortexBrainPulseView: View {
    let color: Color
    let visual: ShellBrainPulseVisual
    var appKind: ShellAppKind = .cortexNode
    var secondaryColor: Color? = nil
    var size: CGFloat = 160
    var showGlyph: Bool = true

    private var pulseMode: ShellNeuralPulseMode {
        switch visual {
        case .active: return .speaking
        case .idle: return .idle
        case .dim: return .idle
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: visual == .dim)) { timeline in
            let motion = ShellBrainPulseMotion.phase(for: visual, date: timeline.date)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.5 * motion.coreOpacity),
                                color.opacity(0.18),
                                color.opacity(0.04),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.08,
                            endRadius: size * 0.42
                        )
                    )
                    .blur(radius: 4)

                ShellNeuralPulseView(color: color, mode: pulseMode, maxRadius: size * 0.34)
                    .frame(width: size, height: size)

                Circle()
                    .stroke(color.opacity(0.32 * motion.ringOpacity), lineWidth: 1.2)
                    .frame(width: size * 0.58, height: size * 0.58)

                if showGlyph {
                    ShellAppCoreOrbView(
                        appKind: appKind,
                        color: color,
                        secondary: secondaryColor ?? color.opacity(0.65),
                        size: size * 0.92,
                        intensity: motion.coreOpacity,
                        orbState: visual == .dim ? .offline : (visual == .active ? .speaking : .idle)
                    )
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(motion.scale)
            .opacity(visual == .dim ? 0.65 : 1)
        }
        .allowsHitTesting(false)
    }
}
