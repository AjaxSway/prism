import SwiftUI

/// Ambient home/intro backdrop — soft glow drift, no particles.
struct ShellAmbientBackground: View {
    let palette: ShellThemePalette
    var accentOverride: Color? = nil
    var intensity: Double = 1.0

    var theme: ShellVisualTheme = .futuristic
    var appKind: ShellAppKind? = nil

    @State private var drift = false

    private var glowColor: Color { accentOverride ?? palette.accent }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            if let appKind {
                ShellAppAmbientLayer(appKind: appKind, accent: glowColor, theme: theme)
                    .ignoresSafeArea()
            }

            RadialGradient(
                colors: [
                    glowColor.opacity(drift ? 0.16 * intensity * palette.glowIntensity : 0.08 * intensity * palette.glowIntensity),
                    glowColor.opacity(0.04 * intensity * palette.glowIntensity),
                    .clear
                ],
                center: drift ? .init(x: 0.45, y: 0.32) : .init(x: 0.55, y: 0.38),
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: drift)

            RadialGradient(
                colors: [.clear, palette.background.opacity(0.85)],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
            .ignoresSafeArea()

            ShellHexGrid(palette: palette)
                .opacity(theme == .futuristic ? 0.35 : 0.06)
        }
        .onAppear { drift = true }
    }
}

private struct ShellHexGrid: View {
    let palette: ShellThemePalette

    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 52
            var y: CGFloat = 0
            while y <= size.height {
                var x: CGFloat = 0
                while x <= size.width {
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: x, y: y))
                            p.addLine(to: CGPoint(x: x + step, y: y))
                        },
                        with: .color(palette.glassStroke.opacity(0.35)),
                        lineWidth: 0.5
                    )
                    x += step
                }
                y += step
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
