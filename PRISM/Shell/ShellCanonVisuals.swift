import SwiftUI

// MARK: - Canon section chrome

struct ShellCanonSectionHeader: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .leading, endPoint: .trailing))
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CORTEXNODE · Integration Ecosystem (#3 canon)

struct ShellCanonIntegrationEcosystemView: View {
    let accent: Color
    var height: CGFloat = 220

    private let satellites: [(label: String, angle: Double)] = [
        ("Data", 0), ("Apps", 51), ("Devices", 103), ("APIs", 154), ("Cloud", 206), ("IoT", 257), ("Analytics", 309)
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                )

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.85 + 0.15 * sin(t * 1.8)

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let hubR = min(size.width, size.height) * 0.11

                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR * 1.6, y: center.y - hubR * 1.6, width: hubR * 3.2, height: hubR * 3.2)),
                        with: .radialGradient(
                            Gradient(colors: [accent.opacity(0.35 * pulse), accent.opacity(0.08), .clear]),
                            center: center, startRadius: 0, endRadius: hubR * 2.2
                        )
                    )

                    let orbitR = min(size.width, size.height) * 0.38
                    for sat in satellites {
                        let a = sat.angle * .pi / 180
                        let pt = CGPoint(x: center.x + cos(a) * orbitR, y: center.y + sin(a) * orbitR)
                        var line = Path()
                        line.move(to: center)
                        line.addLine(to: pt)
                        ctx.stroke(line, with: .color(accent.opacity(0.22)), lineWidth: 0.8)

                        let dot = CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)
                        ctx.fill(Path(ellipseIn: dot), with: .color(accent.opacity(0.55)))
                    }

                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR, y: center.y - hubR, width: hubR * 2, height: hubR * 2)),
                        with: .radialGradient(
                            Gradient(colors: [.white.opacity(0.9), accent]),
                            center: center, startRadius: 0, endRadius: hubR
                        )
                    )
                }
            }

            VStack {
                Spacer()
                HStack {
                    ForEach(satellites.prefix(4), id: \.label) { s in
                        Text(s.label)
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(accent.opacity(0.65))
                            .frame(maxWidth: .infinity)
                    }
                }
                HStack {
                    ForEach(satellites.suffix(3), id: \.label) { s in
                        Text(s.label)
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(accent.opacity(0.65))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(10)

            VStack {
                Text("CORTEX")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                Text("CORE")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(0.8))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Five Layers · One System (#6 canon)

struct ShellCanonFiveLayersView: View {
    let accent: Color

    private let layers: [(name: String, role: String, color: Color)] = [
        ("CORTEX", "Intelligence", Color(red: 0, green: 0.78, blue: 0.95)),
        ("CORTEXNODE", "Network", Color(red: 0.58, green: 0.64, blue: 0.72)),
        ("Signal Zero", "Execution", Color(red: 0.13, green: 0.83, blue: 0.93)),
        ("JERICHO", "Protection", Color(red: 0.94, green: 0.27, blue: 0.27)),
        ("PRISM", "Communication", Color(red: 0.66, green: 0.33, blue: 0.97))
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(layers.enumerated()), id: \.offset) { i, layer in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(layer.color)
                        .frame(width: 4, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(layer.name.uppercased())
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(layer.role)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    Text("Preview")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(layer.color.opacity(i == 1 ? 0.12 : 0.06))
                if i < layers.count - 1 {
                    Rectangle().fill(accent.opacity(0.12)).frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Control Center strip (#9 canon)

struct ShellCanonControlCenterStrip: View {
    let accent: Color

    private let tiles: [(String, String, String)] = [
        ("Overview", "System map", "rectangle.3.group"),
        ("Analytics", "Mock metrics", "chart.xyaxis.line"),
        ("Data Flow", "Topology preview", "arrow.triangle.branch"),
        ("Operations", "Gated actions", "slider.horizontal.3")
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(tiles, id: \.0) { tile in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: tile.2)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                    Text(tile.0.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text(tile.1)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.18), lineWidth: 1))
                )
            }
        }
    }
}

// MARK: - JERICHO · Protection Layer (#8 canon)

struct ShellCanonJerichoProtectionView: View {
    let red: Color
    let blue: Color
    var height: CGFloat = 200

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [red.opacity(0.08), blue.opacity(0.06), Color.black.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(red.opacity(0.35), lineWidth: 1))

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.9 + 0.1 * sin(t * 2.2)

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let shieldH = size.height * 0.42
                    let shieldW = size.width * 0.28

                    var shield = Path()
                    shield.move(to: CGPoint(x: center.x, y: center.y - shieldH))
                    shield.addLine(to: CGPoint(x: center.x + shieldW, y: center.y - shieldH * 0.2))
                    shield.addLine(to: CGPoint(x: center.x + shieldW * 0.85, y: center.y + shieldH * 0.55))
                    shield.addQuadCurve(to: CGPoint(x: center.x - shieldW * 0.85, y: center.y + shieldH * 0.55),
                                        control: CGPoint(x: center.x, y: center.y + shieldH * 0.75))
                    shield.addLine(to: CGPoint(x: center.x - shieldW, y: center.y - shieldH * 0.2))
                    shield.closeSubpath()

                    ctx.stroke(shield, with: .color(red.opacity(0.55 * pulse)), lineWidth: 2)
                    ctx.stroke(shield, with: .color(blue.opacity(0.35)), lineWidth: 0.8)

                    for i in 0..<3 {
                        let r = shieldW * CGFloat(i + 1) / 3.5
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r * 0.5, width: r * 2, height: r)),
                            with: .color(blue.opacity(0.12)),
                            lineWidth: 0.6
                        )
                    }

                    let core = CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)
                    ctx.fill(Path(ellipseIn: core), with: .color(red.opacity(0.9)))
                }
            }

            VStack(spacing: 4) {
                Spacer()
                Text("SHIELD CORE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(red.opacity(0.8))
                Text("Monitor · Defend · Secure · Resilience")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 10)
            }
        }
        .frame(height: height)
    }
}

struct ShellCanonJerichoPillarsView: View {
    let red: Color
    let blue: Color

    private let pillars = ["Monitor", "Defend", "Secure", "Resilience"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pillars.enumerated()), id: \.offset) { i, name in
                VStack(spacing: 6) {
                    Circle()
                        .fill(i % 2 == 0 ? red.opacity(0.25) : blue.opacity(0.25))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(i % 2 == 0 ? red : blue, lineWidth: 1))
                    Text(name.uppercased())
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - PRISM · Communication Grid (#5 canon)

struct ShellCanonPrismCommunicationGridView: View {
    let violet: Color
    let pink: Color
    var height: CGFloat = 240

    private let channels: [(String, Double)] = [
        ("Blog", 270), ("Email", 306), ("SMS", 342), ("Podcast", 18),
        ("YouTube", 54), ("Instagram", 90), ("X", 126), ("LinkedIn", 162),
        ("TikTok", 198), ("Facebook", 234)
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [violet.opacity(0.12), Color.black.opacity(0.5), pink.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(violet.opacity(0.35), lineWidth: 1))

            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let shimmer = 0.7 + 0.3 * sin(t * 3)

                Canvas { ctx, size in
                    let source = CGPoint(x: size.width * 0.12, y: size.height / 2)
                    let coreR: CGFloat = 14
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: source.x - coreR, y: source.y - coreR, width: coreR * 2, height: coreR * 2)),
                        with: .radialGradient(
                            Gradient(colors: [.white, violet]),
                            center: source, startRadius: 0, endRadius: coreR
                        )
                    )

                    let hubX = size.width * 0.38
                    let hub = CGPoint(x: hubX, y: size.height / 2)
                    var beam = Path()
                    beam.move(to: source)
                    beam.addLine(to: hub)
                    ctx.stroke(beam, with: .color(violet.opacity(0.7 * shimmer)), lineWidth: 2.5)

                    let orbitR = size.width * 0.42
                    for ch in channels {
                        let a = ch.1 * .pi / 180
                        let pt = CGPoint(x: hub.x + cos(a) * orbitR * 0.55, y: hub.y + sin(a) * orbitR * 0.45)
                        var ray = Path()
                        ray.move(to: hub)
                        ray.addLine(to: pt)
                        ctx.stroke(ray, with: .color(pink.opacity(0.35)), lineWidth: 0.8)
                        let dot = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
                        ctx.fill(Path(ellipseIn: dot), with: .color(violet.opacity(0.6)))
                    }

                    ctx.fill(
                        Path(ellipseIn: CGRect(x: hub.x - 10, y: hub.y - 10, width: 20, height: 20)),
                        with: .color(pink.opacity(0.85))
                    )
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SOURCE")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Text("SIGNAL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(violet)
                }
                .padding(.leading, 12)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("REFRACTION")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(pink.opacity(0.8))
                    Text("10 CHANNELS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.trailing, 12)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Adaptive learning flow (command / about accent)

struct ShellCanonAdaptiveFlowView: View {
    let accent: Color
    var height: CGFloat = 72

    var body: some View {
        HStack(spacing: 0) {
            flowNode("Inputs", accent.opacity(0.5))
            flowArrow(accent)
            flowNode("Intelligence", accent)
            flowArrow(accent)
            flowNode("Outputs", Color(red: 0.55, green: 0.36, blue: 0.98))
        }
        .frame(height: height)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.15), lineWidth: 1))
        )
    }

    private func flowNode(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Circle().fill(color.opacity(0.35)).frame(width: 14, height: 14)
            Text(label.uppercased())
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func flowArrow(_ color: Color) -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(color.opacity(0.4))
    }
}

// MARK: - NODE · data flow lanes

struct ShellCanonDataFlowLanesView: View {
    let accent: Color
    var height: CGFloat = 140

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(t.truncatingRemainder(dividingBy: 2.0) / 2.0)

            Canvas { ctx, size in
                let lanes = 4
                let laneH = size.height / CGFloat(lanes + 1)
                for i in 0..<lanes {
                    let y = laneH * CGFloat(i + 1)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: .color(accent.opacity(0.15)), lineWidth: 0.6)

                    let dotX = size.width * (0.15 + phase * 0.7).truncatingRemainder(dividingBy: 1.0)
                    let dot = CGRect(x: dotX - 4, y: y - 4, width: 8, height: 8)
                    ctx.fill(Path(ellipseIn: dot), with: .color(accent.opacity(0.55)))
                }
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.15), lineWidth: 1))
        )
    }
}
