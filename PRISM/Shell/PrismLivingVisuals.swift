import SwiftUI

// MARK: - Living border · animated panel chrome

struct PrismLivingBorder: View {
    let accent: Color
    var secondary: Color? = nil
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 1.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.45 + 0.55 * (sin(t * 2.2) + 1) / 2
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            accent.opacity(0.15 + 0.35 * pulse),
                            (secondary ?? accent).opacity(0.55 * pulse),
                            Color.cyan.opacity(0.22 * pulse),
                            accent.opacity(0.12)
                        ],
                        center: .center,
                        angle: .degrees(t * 42)
                    ),
                    lineWidth: lineWidth
                )
        }
        .allowsHitTesting(false)
    }
}

struct PrismLivingBorderModifier: ViewModifier {
    let accent: Color
    var secondary: Color? = nil
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content.overlay {
            PrismLivingBorder(accent: accent, secondary: secondary, cornerRadius: cornerRadius)
        }
    }
}

extension View {
    func prismLivingBorder(accent: Color, secondary: Color? = nil, cornerRadius: CGFloat = 12) -> some View {
        modifier(PrismLivingBorderModifier(accent: accent, secondary: secondary, cornerRadius: cornerRadius))
    }
}

// MARK: - Premium PRISM hero core (no dead mp4 · real graphics + motion)

struct PrismHeroCoreView: View {
    let config: ShellHeroBrainConfig
    var orbState: ShellOrbState = .idle
    var size: CGFloat = 280

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stateBoost: Double {
        switch orbState {
        case .executing, .thinking: return 1.35
        case .speaking, .listening: return 1.15
        case .success: return 1.05
        default: return 1.0
        }
    }

    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.82 + 0.18 * sin(t * 1.6 * stateBoost)

                ZStack {
                    Image("PRISMIntroHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size * 1.05, height: size * 1.05)
                        .opacity(0.42 + 0.12 * pulse)
                        .blur(radius: 0.6)
                        .scaleEffect(1.0 + CGFloat(sin(t * 0.9)) * 0.018)

                    Canvas { ctx, canvasSize in
                        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                        let maxR = min(canvasSize.width, canvasSize.height) / 2

                        for ring in 1...4 {
                            let r = maxR * (0.52 + CGFloat(ring) * 0.11) + CGFloat(sin(t * 1.4 + Double(ring))) * 4
                            ctx.stroke(
                                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                                with: .color(config.accent.opacity(0.08 + Double(ring) * 0.04 * pulse)),
                                lineWidth: 0.9
                            )
                        }

                        for i in 0..<6 {
                            let angle = Double(i) * .pi / 3 + t * (orbState == .executing ? 0.35 : 0.18)
                            let inner = maxR * 0.22
                            let outer = maxR * (0.88 + 0.06 * sin(t * 2.5 + Double(i)))
                            var ray = Path()
                            ray.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                            ray.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                            ctx.stroke(
                                ray,
                                with: .linearGradient(
                                    Gradient(colors: [config.accent.opacity(0.55 * pulse), config.secondary.opacity(0.35), .clear]),
                                    startPoint: center,
                                    endPoint: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer)
                                ),
                                lineWidth: 1.4
                            )
                        }

                        if orbState == .executing || orbState == .thinking {
                            for scan in 0..<2 {
                                let y = canvasSize.height * (0.25 + CGFloat(scan) * 0.35 + CGFloat(sin(t * 3 + Double(scan))) * 0.04)
                                var line = Path()
                                line.move(to: CGPoint(x: 0, y: y))
                                line.addLine(to: CGPoint(x: canvasSize.width, y: y))
                                ctx.stroke(line, with: .color(config.secondary.opacity(0.18)), lineWidth: 0.7)
                            }
                        }
                    }
                    .frame(width: size, height: size)
                }
            }

            ShellPrismCoreOrb(
                violet: config.accent,
                pink: config.secondary,
                size: size * 0.72,
                intensity: stateBoost,
                orbState: orbState
            )
            .shadow(color: config.accent.opacity(0.55), radius: orbState == .executing ? 24 : 14)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Module glyphs · not generic SF Symbol tiles

struct PrismModuleGlyphView: View {
    let moduleId: String
    let accent: Color
    var secondary: Color? = nil
    var size: CGFloat = 36

    private var pink: Color { secondary ?? Color(red: 0.925, green: 0.286, blue: 0.600) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let r = min(canvasSize.width, canvasSize.height) / 2 - 2

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                    with: .radialGradient(
                        Gradient(colors: [accent.opacity(0.22), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: r
                    )
                )

                switch moduleId {
                case "signal_composer":
                    for i in 0..<5 {
                        let h = 4 + CGFloat(abs(sin(t * 3.2 + Double(i) * 0.9))) * 10
                        let x = center.x - 12 + CGFloat(i) * 6
                        ctx.fill(
                            Path(roundedRect: CGRect(x: x, y: center.y - h / 2, width: 3, height: h), cornerRadius: 1),
                            with: .color(accent.opacity(0.85))
                        )
                    }
                case "platform_outputs":
                    for i in 0..<3 {
                        let offset = CGFloat(i) * 5 + CGFloat(sin(t * 1.8 + Double(i))) * 1.5
                        ctx.stroke(
                            Path(roundedRect: CGRect(x: center.x - 10 + offset, y: center.y - 8 + offset, width: 14, height: 10), cornerRadius: 2),
                            with: .color(accent.opacity(0.65 - Double(i) * 0.12)),
                            lineWidth: 1.2
                        )
                    }
                case "refraction_preview":
                    var beam = Path()
                    beam.move(to: CGPoint(x: center.x - 12, y: center.y))
                    beam.addLine(to: center)
                    beam.addLine(to: CGPoint(x: center.x + 12, y: center.y - 8))
                    beam.addLine(to: CGPoint(x: center.x + 12, y: center.y + 8))
                    beam.closeSubpath()
                    ctx.stroke(beam, with: .color(pink.opacity(0.75)), lineWidth: 1.2)
                case "campaign_calendar":
                    ctx.stroke(Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)), with: .color(accent.opacity(0.6)), lineWidth: 1)
                    for i in 0..<4 {
                        let a = Double(i) * .pi / 2 + t * 0.5
                        let pt = CGPoint(x: center.x + cos(a) * 8, y: center.y + sin(a) * 8)
                        ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4)), with: .color(pink.opacity(0.8)))
                    }
                case "brand_voice":
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: center.x - 8, y: center.y - 6)); p.addQuadCurve(to: CGPoint(x: center.x - 8, y: center.y + 6), control: CGPoint(x: center.x - 14, y: center.y)) }, with: .color(accent), lineWidth: 1.4)
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: center.x + 8, y: center.y + 6)); p.addQuadCurve(to: CGPoint(x: center.x + 8, y: center.y - 6), control: CGPoint(x: center.x + 14, y: center.y)) }, with: .color(pink), lineWidth: 1.4)
                case "audience_selector":
                    for i in -1...1 {
                        let x = center.x + CGFloat(i) * 8
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: center.y - 8, width: 6, height: 6)), with: .color(accent.opacity(0.8)))
                        ctx.stroke(Path(ellipseIn: CGRect(x: x - 5, y: center.y, width: 10, height: 8)), with: .color(accent.opacity(0.45)), lineWidth: 0.8)
                    }
                case "draft_queue":
                    ctx.stroke(Path(roundedRect: CGRect(x: center.x - 12, y: center.y - 4, width: 24, height: 12), cornerRadius: 2), with: .color(accent.opacity(0.55)), lineWidth: 1)
                    for i in 0..<3 {
                        let y = center.y - 2 + CGFloat(i) * 3 - CGFloat(sin(t * 2 + Double(i))) * 1.5
                        ctx.fill(Path(roundedRect: CGRect(x: center.x - 9, y: y, width: 18, height: 2), cornerRadius: 1), with: .color(pink.opacity(0.7)))
                    }
                case "distribution_status":
                    var fork = Path()
                    fork.move(to: CGPoint(x: center.x - 10, y: center.y + 6))
                    fork.addLine(to: CGPoint(x: center.x, y: center.y - 8))
                    fork.addLine(to: CGPoint(x: center.x + 10, y: center.y + 6))
                    ctx.stroke(fork, with: .color(accent), lineWidth: 1.2)
                case "proof_assets":
                    ctx.stroke(Path(roundedRect: CGRect(x: center.x - 8, y: center.y - 10, width: 16, height: 20), cornerRadius: 2), with: .color(accent.opacity(0.65)), lineWidth: 1)
                    let shimmerY = center.y - 6 + CGFloat(sin(t * 2.8)) * 8
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: center.x - 5, y: shimmerY)); p.addLine(to: CGPoint(x: center.x + 5, y: shimmerY)) }, with: .color(pink.opacity(0.75)), lineWidth: 1)
                case "image_studio":
                    ctx.stroke(Path(roundedRect: CGRect(x: center.x - 11, y: center.y - 9, width: 22, height: 16), cornerRadius: 3), with: .color(accent.opacity(0.7)), lineWidth: 1.1)
                    ctx.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(pink.opacity(0.65 + 0.35 * sin(t * 3))))
                case "approval_gate":
                    ctx.stroke(Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), with: .color(accent.opacity(0.55 + 0.25 * sin(t * 2))), lineWidth: 1.2)
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: center.x - 5, y: center.y)); p.addLine(to: CGPoint(x: center.x - 1, y: center.y + 4)); p.addLine(to: CGPoint(x: center.x + 6, y: center.y - 5)) }, with: .color(pink), lineWidth: 1.3)
                case "audit_trail":
                    for i in 0..<4 {
                        let y = center.y - 8 + CGFloat(i) * 5
                        let w = 10 + CGFloat(i) * 3
                        ctx.fill(Path(roundedRect: CGRect(x: center.x - w / 2, y: y, width: w, height: 2), cornerRadius: 1), with: .color(accent.opacity(0.45 + Double(i) * 0.12)))
                    }
                default:
                    ctx.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(accent))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Living empty state · not a frozen SF Symbol slab

struct PrismLivingEmptyState: View {
    let palette: ShellThemePalette
    let title: String
    let message: String
    var accent: Color? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    private var violet: Color { accent ?? palette.accent }
    private var pink: Color { Color(red: 0.925, green: 0.286, blue: 0.600) }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                PrismPulseRing(color: violet, secondary: pink, diameter: 88, lineWidth: 1.2, speed: 1.1)
                ShellPrismCoreOrb(violet: violet, pink: pink, size: 52, intensity: 0.95, orbState: .idle)
            }
            .frame(height: 96)

            Text(title)
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
            Text(message)
                .font(palette.bodyFont)
                .foregroundColor(palette.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                ShellPrimaryButton(title: actionTitle, palette: palette, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.backgroundElevated.opacity(0.65))
        )
        .prismLivingBorder(accent: violet, secondary: pink)
        .prismLivingCard(accent: violet)
    }
}

// MARK: - About / Trust hero strip

struct PrismTrustHeroBanner: View {
    let config: PremiumShellConfig
    let palette: ShellThemePalette
    var orbState: ShellOrbState = .idle

    private var violet: Color { config.refractionAccent ?? palette.accent }
    private var pink: Color { config.refractionPink ?? config.accentDeep }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.07, green: 0.02, blue: 0.12), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let origin = CGPoint(x: size.width * 0.15, y: size.height * 0.5)
                    for i in 0..<3 {
                        var beam = Path()
                        beam.move(to: origin)
                        beam.addLine(to: CGPoint(x: size.width * 0.95, y: size.height * (0.25 + CGFloat(i) * 0.22 + CGFloat(sin(t + Double(i)) * 0.03))))
                        ctx.stroke(beam, with: .color(violet.opacity(0.08)), lineWidth: 0.8)
                    }
                }
            }

            HStack(spacing: 16) {
                PrismHeroCoreView(config: .prism, orbState: orbState, size: 96)
                    .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text("CORTEX ECOSYSTEM")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(violet.opacity(0.7))
                        .tracking(1.5)
                    Text(config.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Draft-only · Approval required · Honest labels")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(palette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(minHeight: 128)
        .prismLivingBorder(accent: violet, secondary: pink, cornerRadius: 16)
    }
}
