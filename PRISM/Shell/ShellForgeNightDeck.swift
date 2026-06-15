import SwiftUI

// MARK: - FORGE Night · SwiftUI-native energy decks (no bundled stock video)

/// CORTEXNODE · Nervous system command deck — inspired by cyan wireframe plexus references.
struct ShellNervousSystemDeck: View {
    let accent: Color
    let secondary: Color
    var orbState: ShellOrbState = .idle
    var onOrbTap: (() -> Void)? = nil

    private var pulseVisual: ShellBrainPulseVisual { ShellBrainPulseVisual.from(orbState: orbState) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.06), Color.black, Color(white: 0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [accent.opacity(0.45), secondary.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
                    let nodes: [(String, Double, Double)] = [
                        ("CORTEX", 0, -0.34),
                        ("Signal Zero", 0.38, -0.12),
                        ("JERICHO", -0.38, -0.12),
                        ("PRISM", 0.42, 0.22),
                        ("FORGE", -0.42, 0.22),
                        ("ATLAS", 0, 0.36),
                    ]

                    for ring in 1...3 {
                        let r = min(size.width, size.height) * (0.14 + CGFloat(ring) * 0.11)
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(accent.opacity(0.08 + Double(ring) * 0.04)),
                            lineWidth: 0.8
                        )
                    }

                    for (idx, node) in nodes.enumerated() {
                        let phase = t * 0.9 + Double(idx) * 0.7
                        let nx = center.x + CGFloat(node.1) * size.width * 0.38
                        let ny = center.y + CGFloat(node.2) * size.height * 0.38

                        var path = Path()
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: nx, y: ny))
                        ctx.stroke(path, with: .color(accent.opacity(0.18)), lineWidth: 0.7)

                        let flow = (sin(phase) + 1) / 2
                        let fx = center.x + (nx - center.x) * CGFloat(flow)
                        let fy = center.y + (ny - center.y) * CGFloat(flow)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: fx - 2.5, y: fy - 2.5, width: 5, height: 5)),
                            with: .color(accent.opacity(0.55))
                        )

                        ctx.fill(
                            Path(ellipseIn: CGRect(x: nx - 5, y: ny - 5, width: 10, height: 10)),
                            with: .color(secondary.opacity(0.55))
                        )
                    }
                }
            }

            VStack(spacing: 10) {
                Text("NERVOUS SYSTEM · MOCK TOPOLOGY")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(accent.opacity(0.55))
                    .tracking(2)

                ZStack {
                    ShellCoreEngine(color: accent, size: 56, intensity: 0.85, geometry: .network, showTriangle: false)
                        .opacity(0.35)
                    ShellCortexBrainPulseView(
                        color: accent,
                        visual: pulseVisual,
                        appKind: .cortexNode,
                        secondaryColor: secondary,
                        size: 118,
                        showGlyph: true
                    )
                }
                .onTapGesture { onOrbTap?() }

                Text("NODE CORE · \(orbState.label.uppercased()) · SHELL PREVIEW")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.42))

                Text("Not connected · Connect later · Offline preview")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(secondary.opacity(0.65))
            }
            .padding(.vertical, 18)
        }
        .frame(height: 320)
        .shadow(color: accent.opacity(0.12), radius: 24, y: 8)
    }
}

/// JERICHO · Immune vault deck — inspired by flesh-brain + red shield mesh references.
struct ShellImmuneVaultDeck: View {
    let red: Color
    let steel: Color
    var orbState: ShellOrbState = .idle
    var onOrbTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(white: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [red.opacity(0.55), steel.opacity(0.25)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.2
                        )
                )

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                    for i in 0..<6 {
                        let angle = Double(i) * .pi / 3 + t * 0.15
                        let r = min(size.width, size.height) * 0.34
                        var hex = Path()
                        for j in 0..<6 {
                            let a = angle + Double(j) * .pi / 3
                            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.72)
                            if j == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
                        }
                        hex.closeSubpath()
                        ctx.stroke(hex, with: .color(red.opacity(i == 0 ? 0.35 : 0.12)), lineWidth: i == 0 ? 1.4 : 0.7)
                    }

                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 40, y: center.y))
                    cross.addLine(to: CGPoint(x: center.x + 40, y: center.y))
                    cross.move(to: CGPoint(x: center.x, y: center.y - 28))
                    cross.addLine(to: CGPoint(x: center.x, y: center.y + 28))
                    ctx.stroke(cross, with: .color(steel.opacity(0.25)), lineWidth: 0.8)
                }
            }

            VStack(spacing: 12) {
                Text("IMMUNE VAULT · ADVISORY ONLY")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(red.opacity(0.7))
                    .tracking(2)

                ShellCortexBrainPulseView(
                    color: red,
                    visual: ShellBrainPulseVisual.from(orbState: orbState),
                    appKind: .jericho,
                    secondaryColor: steel,
                    size: 124,
                    showGlyph: true
                )
                .onTapGesture { onOrbTap?() }

                Text("JERICHO CORE · \(orbState.label.uppercased()) · SHELL PREVIEW")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))

                HStack(spacing: 16) {
                    vaultChip("Trust Gate", red)
                    vaultChip("Audit Preview", steel)
                    vaultChip("Not connected", .white.opacity(0.35))
                }
            }
            .padding(.vertical, 16)
        }
        .frame(height: 300)
    }

    private func vaultChip(_ label: String, _ color: Color) -> some View {
        Text(label.uppercased())
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundColor(color.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

/// PRISM · Refraction beam deck — inspired by purple brain + lateral cyan beam references.
struct ShellRefractionBeamDeck: View {
    let violet: Color
    let pink: Color
    let cyan: Color
    var orbState: ShellOrbState = .idle
    var onOrbTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.02, blue: 0.14), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [violet.opacity(0.5), pink.opacity(0.25), cyan.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1
                        )
                )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let center = CGPoint(x: size.width * 0.38, y: size.height * 0.45)
                    for i in 0..<5 {
                        let spread = CGFloat(i - 2) * 0.08
                        var beam = Path()
                        beam.move(to: center)
                        beam.addLine(to: CGPoint(x: size.width * (0.72 + spread), y: size.height * (0.22 + spread * 2)))
                        ctx.stroke(
                            beam,
                            with: .linearGradient(
                                Gradient(colors: [violet.opacity(0.5), cyan.opacity(0.35), .clear]),
                                startPoint: center,
                                endPoint: CGPoint(x: size.width, y: 0)
                            ),
                            lineWidth: 1.2
                        )
                    }

                    let shimmer = 0.35 + 0.25 * sin(t * 2.4)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - 28, y: center.y - 28, width: 56, height: 56)),
                        with: .radialGradient(
                            Gradient(colors: [violet.opacity(shimmer), pink.opacity(0.2), .clear]),
                            center: center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                }
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ONE SIGNAL IN")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(violet.opacity(0.75))
                    ShellCortexBrainPulseView(
                        color: violet,
                        visual: ShellBrainPulseVisual.from(orbState: orbState),
                        appKind: .prism,
                        secondaryColor: pink,
                        size: 96,
                        showGlyph: true
                    )
                    .onTapGesture { onOrbTap?() }
                    Text("PRISM CORE · DRAFT ONLY")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.leading, 20)

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("EVERY CHANNEL OUT")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(cyan.opacity(0.7))
                    ForEach(["Email", "X", "LinkedIn", "Studio"], id: \.self) { ch in
                        HStack(spacing: 6) {
                            Text(ch.uppercased())
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.55))
                            Circle().fill(pink.opacity(0.4)).frame(width: 5, height: 5)
                        }
                    }
                    Text("Not connected · Approval required")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(.white.opacity(0.32))
                }
                .padding(.trailing, 18)
            }
        }
        .frame(height: 200)
    }
}

/// Intro energy wash — subtle, no over-glow.
struct ShellIntroEnergyWash: View {
    let accent: Color
    let appKind: ShellAppKind

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.55)
                let pulse = 0.5 + 0.5 * sin(t * 1.2)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - 120, y: center.y - 120, width: 240, height: 240)),
                    with: .radialGradient(
                        Gradient(colors: [accent.opacity(0.12 * pulse), accent.opacity(0.03), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )

                if appKind == .jericho {
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - 90, y: center.y - 90, width: 180, height: 180)),
                        with: .color(accent.opacity(0.15)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Distinct module tile — not generic cards.
struct ShellForgeModuleTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let palette: ShellThemePalette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [accent, accent.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                        )
                    Spacer()
                    Circle()
                        .fill(palette.offline)
                        .frame(width: 6, height: 6)
                }
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.035))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accent.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
