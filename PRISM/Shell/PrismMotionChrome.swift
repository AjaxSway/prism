import SwiftUI

// MARK: - PRISM living motion · stagger · pulse · topology

struct PrismLivingStatusDot: View {
    let color: Color
    var active: Bool = true
    var size: CGFloat = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.55 + 0.45 * sin(t * 2.8)
            ZStack {
                Circle()
                    .fill(color.opacity(active ? 0.25 * pulse : 0.12))
                    .frame(width: size * 2.4, height: size * 2.4)
                Circle()
                    .fill(color.opacity(active ? 0.85 + 0.15 * pulse : 0.35))
                    .frame(width: size, height: size)
            }
        }
    }
}

struct PrismPulseRing: View {
    let color: Color
    var secondary: Color? = nil
    var diameter: CGFloat = 72
    var lineWidth: CGFloat = 1.4
    var speed: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let wave = 0.35 + 0.65 * (sin(t * speed * 2.4) + 1) / 2
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12 + 0.18 * wave), lineWidth: lineWidth)
                    .frame(width: diameter, height: diameter)
                Circle()
                    .stroke((secondary ?? color).opacity(0.08 + 0.14 * wave), lineWidth: lineWidth * 0.7)
                    .frame(width: diameter * 0.82, height: diameter * 0.82)
                    .rotationEffect(.degrees(t * 18 * speed))
            }
        }
        .allowsHitTesting(false)
    }
}

struct PrismStaggerAppearModifier: ViewModifier {
    let index: Int
    let accent: Color
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .scaleEffect(visible ? 1 : 0.97)
            .onAppear {
                withAnimation(.spring(response: 0.46, dampingFraction: 0.82).delay(Double(index) * 0.045)) {
                    visible = true
                }
            }
    }
}

extension View {
    func prismStaggerAppear(index: Int, accent: Color = .purple) -> some View {
        modifier(PrismStaggerAppearModifier(index: index, accent: accent))
    }

    func prismLivingCard(accent: Color) -> some View {
        shellShimmer(accent: accent.opacity(0.55))
    }
}

/// Animated refraction topology for Modules tab — not a dead static map.
struct ShellPrismLivingTopologyView: View {
    let palette: ShellThemePalette
    let config: PremiumShellConfig
    var orbState: ShellOrbState = .idle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.background.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(palette.accent.opacity(0.22), lineWidth: 1)
                )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let hubPulse = 0.7 + 0.3 * sin(t * 2.2)
                let beamSpeed = orbState == .executing || orbState == .thinking ? 2.4 : 1.2

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let hubR: CGFloat = 16 + CGFloat(hubPulse) * 4

                    // Hub atmosphere — wider radial glow
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR * 2.4, y: center.y - hubR * 2.4, width: hubR * 4.8, height: hubR * 4.8)),
                        with: .radialGradient(
                            Gradient(colors: [palette.accent.opacity(0.45), palette.accent.opacity(0.12), .clear]),
                            center: center,
                            startRadius: 0,
                            endRadius: hubR * 2.8
                        )
                    )

                    for (idx, node) in config.topologyNodes.enumerated() {
                        let pt = CGPoint(x: center.x + node.offsetX, y: center.y + node.offsetY)

                        // Beam with shimmer
                        var line = Path()
                        line.move(to: center)
                        line.addLine(to: pt)
                        let shimmer = 0.22 + 0.28 * sin(t * beamSpeed + Double(node.offsetX) * 0.02)
                        ctx.stroke(line, with: .color(palette.accent.opacity(shimmer)), lineWidth: 1.3)

                        // Animated trace packet along beam
                        let travel = CGFloat((t * 0.55 + Double(idx) * 0.2).truncatingRemainder(dividingBy: 1.0))
                        let tracePt = CGPoint(x: center.x + node.offsetX * travel, y: center.y + node.offsetY * travel)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: tracePt.x - 2.5, y: tracePt.y - 2.5, width: 5, height: 5)),
                            with: .radialGradient(
                                Gradient(colors: [palette.accent.opacity(0.9), .clear]),
                                center: tracePt, startRadius: 0, endRadius: 4
                            )
                        )

                        // Satellite node — outer glow ring
                        let nodePulse = 0.55 + 0.45 * sin(t * 2.6 + Double(node.offsetY) * 0.015)
                        let dotR: CGFloat = 8 + CGFloat(nodePulse) * 3
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - dotR * 1.9, y: pt.y - dotR * 1.9, width: dotR * 3.8, height: dotR * 3.8)),
                            with: .radialGradient(
                                Gradient(colors: [palette.accent.opacity(0.28), .clear]),
                                center: pt, startRadius: 0, endRadius: dotR * 2.2
                            )
                        )
                        // Satellite node — core
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - dotR, y: pt.y - dotR, width: dotR * 2, height: dotR * 2)),
                            with: .radialGradient(
                                Gradient(colors: [palette.accent.opacity(0.92), palette.accent.opacity(0.35)]),
                                center: pt, startRadius: 0, endRadius: dotR
                            )
                        )
                    }

                    // Hub core
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR, y: center.y - hubR, width: hubR * 2, height: hubR * 2)),
                        with: .radialGradient(
                            Gradient(colors: [.white.opacity(0.95), palette.accent]),
                            center: center, startRadius: 0, endRadius: hubR
                        )
                    )

                    for ring in 1...3 {
                        let r = hubR * 1.4 + CGFloat(ring) * 20 + CGFloat(sin(t * 1.4 + Double(ring))) * 4
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(palette.accent.opacity(0.16 - Double(ring) * 0.03)),
                            lineWidth: 0.9
                        )
                    }
                }
            }
            .frame(height: 200)
        }
        .frame(height: 200)
    }
}

/// Idle canvas breathing glow for Image Studio.
struct PrismStudioCanvasGlow: View {
    let violet: Color
    let pink: Color
    var active: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = active ? 0.55 + 0.45 * sin(t * 5.5) : 0.35 + 0.25 * sin(t * 1.6)
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - 90, y: center.y - 70, width: 180, height: 140)),
                    with: .radialGradient(
                        Gradient(colors: [violet.opacity(0.22 * pulse), pink.opacity(0.08), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                if active {
                    for i in 0..<3 {
                        let spread = CGFloat(i) * 0.08
                        var scan = Path()
                        scan.move(to: CGPoint(x: 0, y: size.height * (0.25 + spread + CGFloat(sin(t * 2 + Double(i)) * 0.04))))
                        scan.addLine(to: CGPoint(x: size.width, y: size.height * (0.25 + spread)))
                        ctx.stroke(scan, with: .color(violet.opacity(0.12)), lineWidth: 0.8)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
