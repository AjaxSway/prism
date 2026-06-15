import SwiftUI

struct ShellBrainOrb: View {
    let label: String
    let state: ShellOrbState
    let palette: ShellThemePalette
    var size: OrbSize = .home
    var onTap: () -> Void

    enum OrbSize {
        case home, compact

        var outer: CGFloat { self == .home ? 220 : 148 }
        var ring: CGFloat { self == .home ? 178 : 118 }
        var core: CGFloat { self == .home ? 108 : 72 }
    }

    @State private var breathe = false
    @State private var ringRotation: Double = 0
    @State private var innerRotation: Double = 0

    private var stateColor: Color { palette.orbColor(for: state) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                ZStack {
                    // Outer atmosphere
                    Circle()
                        .fill(stateColor.opacity(breathe ? 0.14 : 0.07))
                        .frame(width: size.outer + 24, height: size.outer + 24)
                        .blur(radius: 6)

                    // Hex frame — NODE icon language
                    HexagonFrame(color: stateColor.opacity(breathe ? 0.55 : 0.28))
                        .frame(width: size.outer, height: size.outer)

                    // Orbital arcs
                    Circle()
                        .stroke(
                            stateColor.opacity(0.42),
                            style: StrokeStyle(lineWidth: 1.4, dash: [10, 7])
                        )
                        .frame(width: size.ring, height: size.ring)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .stroke(
                            palette.accentSoft.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 9])
                        )
                        .frame(width: size.ring * 0.78, height: size.ring * 0.78)
                        .rotationEffect(.degrees(innerRotation))

                    // Neural spokes
                    NeuralSpokes(color: stateColor.opacity(breathe ? 0.55 : 0.32))
                        .frame(width: size.core + 36, height: size.core + 36)

                    // Core reactor
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(state == .speaking ? 0.35 : 0.18),
                                    stateColor.opacity(0.95),
                                    stateColor.opacity(0.25)
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: size.core * 0.52
                            )
                        )
                        .frame(width: size.core, height: size.core)
                        .shadow(color: stateColor.opacity(breathe ? 0.65 : 0.35), radius: breathe ? 24 : 14)

                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                        .frame(width: size.core * 0.42, height: size.core * 0.42)
                }
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: breathe)
                .animation(.easeInOut(duration: 0.4), value: state)

                Text(label.uppercased())
                    .font(size == .home ? palette.titleFont : palette.captionFont)
                    .tracking(size == .home ? 4 : 3)
                    .foregroundColor(palette.textPrimary)

                Text(state.label.uppercased())
                    .font(palette.captionFont)
                    .foregroundColor(stateColor)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            breathe = true
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { ringRotation = 360 }
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: false)) { innerRotation = -360 }
        }
    }
}

private struct HexagonFrame: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            let inset: CGFloat = 8
            ctx.stroke(hexPath(in: rect, inset: inset), with: .color(color), lineWidth: 1.5)
            ctx.stroke(hexPath(in: rect, inset: inset + 8), with: .color(color.opacity(0.35)), lineWidth: 1)
        }
    }

    private func hexPath(in rect: CGRect, inset: CGFloat) -> Path {
        let r = min(rect.width, rect.height) / 2 - inset
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let pt = CGPoint(x: c.x + r * cos(angle), y: c.y + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

private struct NeuralSpokes: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) * 0.42
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let end = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
                var line = Path()
                line.move(to: c)
                line.addLine(to: end)
                ctx.stroke(line, with: .color(color.opacity(i.isMultiple(of: 2) ? 0.7 : 0.35)), lineWidth: 1)
                let dot = CGRect(x: end.x - 2, y: end.y - 2, width: 4, height: 4)
                ctx.fill(Path(ellipseIn: dot), with: .color(color))
            }
        }
        .opacity(pulse ? 1 : 0.75)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
