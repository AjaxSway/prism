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

            VStack(spacing: 12) {
                Text("NERVOUS SYSTEM · MOCK TOPOLOGY")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(accent.opacity(0.55))
                    .tracking(2)

                ShellHeroBrainView(
                    config: .node,
                    size: 312,
                    orbState: orbState,
                    subtitle: "Not connected · Connect later · Offline preview",
                    onTap: { onOrbTap?() }
                )

                Text("Platform nervous system · Seven-layer map · Shell preview")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(secondary.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
        }
        .frame(minHeight: 470)
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

                ShellHeroBrainView(
                    config: .jericho,
                    size: 312,
                    orbState: orbState,
                    subtitle: "Trust gate · Advisory only · Connect later",
                    onTap: { onOrbTap?() }
                )

                HStack(spacing: 12) {
                    vaultChip("Shield", red)
                    vaultChip("Policy Gate", steel)
                    vaultChip("Boundary", red.opacity(0.8))
                    vaultChip("Connect later", .white.opacity(0.35))
                }
            }
            .padding(.vertical, 20)
        }
        .frame(minHeight: 470)
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

                        let travel = CGFloat((t * 0.45 + Double(i) * 0.18).truncatingRemainder(dividingBy: 1.0))
                        let bx = center.x + (size.width * 0.55 - center.x) * travel
                        let by = center.y + (size.height * (0.22 + spread * 2) - center.y) * travel
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: bx - 3, y: by - 3, width: 6, height: 6)),
                            with: .color(pink.opacity(0.55 + 0.35 * sin(t * 3 + Double(i))))
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

            VStack(spacing: 14) {
                Text("REFRACTION · ONE SIGNAL IN · EVERY CHANNEL OUT")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(violet.opacity(0.75))
                    .tracking(1.5)

                ShellHeroBrainView(
                    config: .prism,
                    size: 280,
                    orbState: orbState,
                    subtitle: "Draft-only · Approval required · Not connected",
                    onTap: { onOrbTap?() }
                )

                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    HStack(spacing: 16) {
                        ForEach(Array(["Email", "X", "LinkedIn", "Studio"].enumerated()), id: \.offset) { index, ch in
                            VStack(spacing: 4) {
                                Text(ch.uppercased())
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.55))
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [pink.opacity(0.55 + 0.35 * sin(t * 2.8 + Double(index))), violet.opacity(0.35), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 6
                                        )
                                    )
                                    .frame(width: 7, height: 7)
                                Text("Draft")
                                    .font(.system(size: 6, design: .monospaced))
                                    .foregroundColor(cyan.opacity(0.5 + 0.35 * sin(t * 2.2 + Double(index))))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 18)
        }
        .frame(minHeight: 450)
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
    var moduleId: String? = nil
    var livingMotion: Bool = false
    var isLocked: Bool = false
    var action: () -> Void

    private var effectiveAccent: Color { isLocked ? accent.opacity(0.45) : accent }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if livingMotion, let moduleId {
                        ZStack {
                            PrismPulseRing(color: effectiveAccent, diameter: 34, lineWidth: 0.7, speed: isLocked ? 0.45 : 1.05)
                            PrismModuleGlyphView(moduleId: moduleId, accent: effectiveAccent, size: 28)
                        }
                        .frame(width: 32, height: 32)
                        .opacity(isLocked ? 0.62 : 1.0)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [effectiveAccent, effectiveAccent.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(palette.textSecondary.opacity(0.65))
                    } else if livingMotion {
                        PrismLivingStatusDot(color: accent, active: true, size: 5)
                    } else {
                        Circle()
                            .fill(palette.offline)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(isLocked ? .white.opacity(0.55) : .white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(isLocked ? palette.textSecondary.opacity(0.65) : palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [effectiveAccent, effectiveAccent.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isLocked ? Color.white.opacity(0.02) : Color.white.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(effectiveAccent.opacity(livingMotion ? 0.48 : 0.22), lineWidth: 1)
                    )
                    .shadow(color: effectiveAccent.opacity(livingMotion && !isLocked ? 0.22 : 0.06), radius: livingMotion ? 10 : 4, y: 2)
            )
            .overlay {
                if livingMotion && !isLocked {
                    PrismLivingBorder(accent: accent, cornerRadius: 12, lineWidth: 0.9)
                }
            }
            .shellShimmer(accent: effectiveAccent.opacity(livingMotion ? 0.75 : 0.6))
        }
        .buttonStyle(ShellPressableButtonStyle())
    }
}

// MARK: - Role-specific ambient layers (SwiftUI-native · no bundled video)

struct ShellAppAmbientLayer: View {
    let appKind: ShellAppKind
    let accent: Color
    let theme: ShellVisualTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                switch appKind {
                case .cortexNode:
                    drawNetworkMesh(ctx: ctx, size: size, t: t)
                case .jericho:
                    drawVaultGrid(ctx: ctx, size: size, t: t)
                case .prism:
                    drawRefractionBeams(ctx: ctx, size: size, t: t)
                }
            }
        }
        .opacity(theme == .futuristic ? 0.55 : 0.22)
        .allowsHitTesting(false)
    }

    private func drawNetworkMesh(ctx: GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.35)
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 + t * 0.08
            let r = min(size.width, size.height) * 0.42
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r * 0.55)
            var line = Path()
            line.move(to: center)
            line.addLine(to: pt)
            ctx.stroke(line, with: .color(accent.opacity(0.07)), lineWidth: 0.6)
        }
    }

    private func drawVaultGrid(ctx: GraphicsContext, size: CGSize, t: Double) {
        var y: CGFloat = 0
        while y < size.height {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            ctx.stroke(line, with: .color(accent.opacity(0.04 + 0.02 * sin(t + Double(y) * 0.01))), lineWidth: 0.5)
            y += 48
        }
    }

    private func drawRefractionBeams(ctx: GraphicsContext, size: CGSize, t: Double) {
        let origin = CGPoint(x: size.width * 0.18, y: size.height * 0.38)
        for i in 0..<7 {
            let spread = CGFloat(i) * 0.09
            let wave = 0.05 + 0.04 * sin(t * 1.6 + Double(i))
            var beam = Path()
            beam.move(to: origin)
            beam.addLine(to: CGPoint(x: size.width, y: size.height * (0.12 + spread + CGFloat(sin(t * 0.9 + Double(i)) * 0.04))))
            ctx.stroke(beam, with: .color(accent.opacity(wave)), lineWidth: i == 0 ? 1.1 : 0.7)
        }
        let pulse = 0.12 + 0.08 * sin(t * 2.1)
        ctx.fill(
            Path(ellipseIn: CGRect(x: origin.x - 40, y: origin.y - 40, width: 80, height: 80)),
            with: .radialGradient(
                Gradient(colors: [accent.opacity(pulse), accent.opacity(0.04), .clear]),
                center: origin,
                startRadius: 0,
                endRadius: 48
            )
        )
    }
}

/// Compact command-strip heroes for COMMAND tab.
struct ShellNetworkCommandStrip: View {
    let accent: Color
    let secondary: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.25), lineWidth: 1))
            HStack(spacing: 14) {
                ShellCoreEngine(color: accent, size: 52, intensity: 0.9, geometry: .network, showTriangle: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NETWORK COMMAND")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .leading, endPoint: .trailing))
                    Text("Nervous system · Mock topology · Not connected")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(secondary.opacity(0.75))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 88)
    }
}

struct ShellVaultCommandStrip: View {
    let red: Color
    let steel: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(red.opacity(0.3), lineWidth: 1))
            HStack(spacing: 14) {
                ShellJerichoCoreOrb(primary: red, secondary: steel, size: 48, intensity: 0.85)
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRUST COMMAND")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(LinearGradient(colors: [.white, red], startPoint: .leading, endPoint: .trailing))
                    Text("Immune vault · Advisory only · Approval required")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.42))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 88)
    }
}

struct ShellRefractionCommandStrip: View {
    let violet: Color
    let pink: Color
    var orbState: ShellOrbState = .idle

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.4 + 0.6 * (sin(t * 1.8) + 1) / 2
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [violet.opacity(0.12 + 0.08 * pulse), pink.opacity(0.04), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(violet.opacity(0.28), lineWidth: 1)

            HStack(spacing: 14) {
                ShellPrismCoreOrb(violet: violet, pink: pink, size: 48, intensity: 0.9, orbState: orbState)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REFRACTION COMMAND")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(LinearGradient(colors: [violet, pink], startPoint: .leading, endPoint: .trailing))
                    Text("One signal in · Draft-only · Not connected")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.42))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 88)
    }
}

/// System Map module focal — animated topology ring.
struct ShellNetworkTopologyRing: View {
    let accent: Color
    let config: PremiumShellConfig

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.2), lineWidth: 1))

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let spin = t * 12
                    for ring in 1...3 {
                        let r = min(size.width, size.height) * (0.12 + CGFloat(ring) * 0.1)
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(accent.opacity(0.1 + Double(ring) * 0.05)),
                            lineWidth: 0.8
                        )
                    }
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)),
                        with: .color(accent.opacity(0.35))
                    )
                    for node in config.topologyNodes {
                        let pt = CGPoint(x: center.x + node.offsetX * 0.55, y: center.y + node.offsetY * 0.55)
                        var line = Path()
                        line.move(to: center)
                        line.addLine(to: pt)
                        ctx.stroke(line, with: .color(accent.opacity(0.15)), lineWidth: 0.6)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)),
                            with: .color(Color.gray.opacity(0.55))
                        )
                    }
                    var arc = Path()
                    arc.addArc(center: center, radius: min(size.width, size.height) * 0.38, startAngle: .degrees(spin), endAngle: .degrees(spin + 70), clockwise: false)
                    ctx.stroke(arc, with: .color(accent.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 6]))
                }
            }

            VStack {
                Spacer()
                Text("\(config.topologyHubLabel) · OFFLINE PREVIEW")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(0.55))
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 200)
    }
}
