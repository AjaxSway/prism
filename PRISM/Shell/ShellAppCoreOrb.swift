import SwiftUI

/// App-specific NODE / JERICHO / PRISM core orb — the thing Sir talks to.
struct ShellAppCoreOrbView: View {
    let appKind: ShellAppKind
    let color: Color
    let secondary: Color
    var size: CGFloat = 140
    var intensity: Double = 1.0
    var orbState: ShellOrbState = .idle

    var body: some View {
        switch appKind {
        case .cortexNode:
            ShellNodeCoreOrb(color: color, size: size, intensity: intensity)
        case .jericho:
            ShellJerichoCoreOrb(primary: color, secondary: secondary, size: size, intensity: intensity, alert: orbState == .warning || orbState == .error)
        case .prism:
            ShellPrismCoreOrb(violet: color, pink: secondary, size: size, intensity: intensity)
        }
    }
}

// MARK: - NODE · network core

struct ShellNodeCoreOrb: View {
    let color: Color
    var size: CGFloat = 120
    var intensity: Double = 1.0

    var body: some View {
        ShellCoreEngine(color: color, size: size, intensity: intensity, geometry: .network)
    }
}

// MARK: - JERICHO · shield containment

struct ShellJerichoCoreOrb: View {
    let primary: Color
    let secondary: Color
    var size: CGFloat = 120
    var intensity: Double = 1.0
    var alert: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.88 + 0.12 * sin(t * 1.6)
            let accent = alert ? Color(red: 0.98, green: 0.68, blue: 0.12) : primary

            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let maxR = min(canvasSize.width, canvasSize.height) / 2 - 2

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR, y: center.y - maxR, width: maxR * 2, height: maxR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [accent.opacity(0.28 * intensity * pulse), .clear]),
                        center: center, startRadius: 0, endRadius: maxR
                    )
                )

                // Hex shield
                let hexR = maxR * 0.72
                var hex = Path()
                for i in 0..<6 {
                    let a = Double(i) * .pi / 3 - .pi / 2
                    let pt = CGPoint(x: center.x + CGFloat(cos(a)) * hexR, y: center.y + CGFloat(sin(a)) * hexR)
                    if i == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
                }
                hex.closeSubpath()
                ctx.stroke(hex, with: .color(accent.opacity(0.55)), lineWidth: 1.4)
                ctx.stroke(hex, with: .color(secondary.opacity(0.25)), lineWidth: 0.6)

                // Containment rings
                for i in 1...3 {
                    let r = maxR * CGFloat(i) / 3.5
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                        with: .color(accent.opacity(0.15)),
                        lineWidth: 0.8
                    )
                }

                let coreR = maxR * 0.12
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
                    with: .color(accent.opacity(0.9 * intensity))
                )
            }
            .frame(width: size, height: size)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - PRISM · refraction core

struct ShellPrismCoreOrb: View {
    let violet: Color
    let pink: Color
    var size: CGFloat = 120
    var intensity: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.9 + 0.1 * sin(t * 2.4)
            let spin = t * 12

            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let maxR = min(canvasSize.width, canvasSize.height) / 2 - 2

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR, y: center.y - maxR, width: maxR * 2, height: maxR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [violet.opacity(0.35 * pulse), pink.opacity(0.12), .clear]),
                        center: center, startRadius: 0, endRadius: maxR
                    )
                )

                // Refraction triangle beam
                var tri = Path()
                let triR = maxR * 0.55
                for i in 0..<3 {
                    let a = Double(i) * 2 * .pi / 3 - .pi / 2 + spin * .pi / 180
                    let pt = CGPoint(x: center.x + CGFloat(cos(a)) * triR, y: center.y + CGFloat(sin(a)) * triR)
                    if i == 0 { tri.move(to: pt) } else { tri.addLine(to: pt) }
                }
                tri.closeSubpath()
                ctx.stroke(tri, with: .color(violet.opacity(0.5)), lineWidth: 1.2)

                for i in 0..<3 {
                    let inner = triR * 0.45
                    let a = Double(i) * 2 * .pi / 3 - .pi / 2 + spin * .pi / 180
                    let pt = CGPoint(x: center.x + CGFloat(cos(a)) * inner, y: center.y + CGFloat(sin(a)) * inner)
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)), with: .color(pink.opacity(0.7)))
                }

                let coreR = maxR * 0.14
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [.white, violet]),
                        center: center, startRadius: 0, endRadius: coreR
                    )
                )
            }
            .frame(width: size, height: size)
        }
        .allowsHitTesting(false)
    }
}
