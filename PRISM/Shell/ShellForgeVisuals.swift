import SwiftUI
import Darwin

// MARK: - CORTEX core engine (SwiftUI-native — no SF symbols)

enum ShellCoreGeometry {
    case network
    case standard
}

struct ShellCoreEngine: View {
    let color: Color
    var size: CGFloat = 120
    var intensity: Double = 1.0
    var geometry: ShellCoreGeometry = .standard
    var showTriangle: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.85 + 0.15 * sin(t * 2.2)
            let spin = t * 18

            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let maxR = min(canvasSize.width, canvasSize.height) / 2 - 2

                // Bloom
                let bloomR = maxR * 0.95
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - bloomR, y: center.y - bloomR, width: bloomR * 2, height: bloomR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(0.35 * intensity * pulse), color.opacity(0.08), .clear]),
                        center: center,
                        startRadius: 0,
                        endRadius: bloomR
                    )
                )

                // Rings
                for i in 1...4 {
                    let r = maxR * CGFloat(i) / 4.2
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                        with: .color(color.opacity(0.12 + Double(i) * 0.06)),
                        lineWidth: i == 4 ? 1.4 : 0.7
                    )
                }

                // Radial spokes
                for i in 0..<16 {
                    let angle = Double(i) * (.pi * 2 / 16)
                    let inner = maxR * 0.12
                    let outer = maxR * 0.88
                    var spoke = Path()
                    spoke.move(to: CGPoint(
                        x: center.x + CGFloat(cos(angle)) * inner,
                        y: center.y + CGFloat(sin(angle)) * inner
                    ))
                    spoke.addLine(to: CGPoint(
                        x: center.x + CGFloat(cos(angle)) * outer,
                        y: center.y + CGFloat(sin(angle)) * outer
                    ))
                    ctx.stroke(spoke, with: .color(color.opacity(0.22)), lineWidth: 0.6)
                }

                // Rotating dash ring
                let dashR = maxR * 0.72
                var dashRing = Path()
                dashRing.addArc(
                    center: center,
                    radius: dashR,
                    startAngle: .degrees(spin),
                    endAngle: .degrees(spin + 300),
                    clockwise: false
                )
                ctx.stroke(
                    dashRing,
                    with: .color(color.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 1.2, dash: [5, 7])
                )

                // Nested triangle (CORTEX mark)
                if showTriangle {
                    let triR = maxR * 0.28
                    var tri = Path()
                    for i in 0..<3 {
                        let a = Double(i) * 2 * .pi / 3 - .pi / 2
                        let pt = CGPoint(x: center.x + CGFloat(cos(a)) * triR, y: center.y + CGFloat(sin(a)) * triR)
                        if i == 0 { tri.move(to: pt) } else { tri.addLine(to: pt) }
                    }
                    tri.closeSubpath()
                    ctx.stroke(tri, with: .color(color.opacity(0.55)), lineWidth: 1.2)
                    var innerTri = Path()
                    let ir = triR * 0.55
                    for i in 0..<3 {
                        let a = Double(i) * 2 * .pi / 3 - .pi / 2
                        let pt = CGPoint(x: center.x + CGFloat(cos(a)) * ir, y: center.y + CGFloat(sin(a)) * ir)
                        if i == 0 { innerTri.move(to: pt) } else { innerTri.addLine(to: pt) }
                    }
                    innerTri.closeSubpath()
                    ctx.fill(innerTri, with: .color(color.opacity(0.25)))
                }

                // Hot core
                let coreR = maxR * 0.14 * CGFloat(pulse)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [.white, color, color.opacity(0.3)]),
                        center: center,
                        startRadius: 0,
                        endRadius: coreR
                    )
                )
            }
            .frame(width: size, height: size)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Radar HUD (Jericho / NODE map)

struct ShellRadarHUD: View {
    let accent: Color
    @State private var sweepAngle: Double = 0
    @State private var blips: [ShellRadarBlip] = []

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 - 4

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - maxRadius, y: center.y - maxRadius, width: maxRadius * 2, height: maxRadius * 2)),
                with: .color(Color.black.opacity(0.45))
            )

            for i in 1...4 {
                let r = maxRadius * CGFloat(i) / 4
                context.stroke(
                    Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                    with: .color(accent.opacity(0.18)),
                    lineWidth: 0.8
                )
            }

            let endAngle = Angle(degrees: sweepAngle)
            let lineEnd = CGPoint(
                x: center.x + CGFloat(cos(endAngle.radians)) * maxRadius,
                y: center.y + CGFloat(sin(endAngle.radians)) * maxRadius
            )
            var sweepLine = Path()
            sweepLine.move(to: center)
            sweepLine.addLine(to: lineEnd)
            context.stroke(sweepLine, with: .color(accent.opacity(0.85)), lineWidth: 1.5)

            for blip in blips {
                let bx = center.x + CGFloat(cos(blip.angle)) * blip.distance * maxRadius
                let by = center.y + CGFloat(sin(blip.angle)) * blip.distance * maxRadius
                context.fill(Path(ellipseIn: CGRect(x: bx - 2, y: by - 2, width: 4, height: 4)), with: .color(accent.opacity(blip.brightness)))
            }

            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - maxRadius, y: center.y - maxRadius, width: maxRadius * 2, height: maxRadius * 2)),
                with: .color(accent.opacity(0.5)),
                lineWidth: 1.5
            )
        }
        .onAppear {
            blips = ShellRadarBlip.randomSet()
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { sweepAngle = 360 }
        }
        .allowsHitTesting(false)
    }
}

private struct ShellRadarBlip: Identifiable {
    let id = UUID()
    var angle: Double
    var distance: CGFloat
    var brightness: CGFloat

    static func randomSet() -> [ShellRadarBlip] {
        (0..<5).map { _ in
            ShellRadarBlip(
                angle: Double.random(in: 0...(2 * .pi)),
                distance: CGFloat.random(in: 0.25...0.85),
                brightness: CGFloat.random(in: 0.5...1)
            )
        }
    }
}

// MARK: - Circular gauge

struct ShellCircularGauge: View {
    let label: String
    let value: Double
    let accent: Color
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    AngularGradient(colors: [accent.opacity(0.4), accent, accent.opacity(0.7)], center: .center),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.opacity(0.45), radius: 8)
            VStack(spacing: 2) {
                Text("\(Int(value * 100))")
                    .font(.system(size: size * 0.22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(label.uppercased())
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(0.65))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Metallic title

struct ShellMetallicTitle: View {
    let text: String
    var size: CGFloat = 24
    var accent: Color = .cyan

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .monospaced))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, accent.opacity(0.85), .white.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: accent.opacity(0.35), radius: 12, y: 2)
    }
}

// MARK: - HUD bracket panel

struct ShellHUDBracketPanel<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent.opacity(0.22), lineWidth: 1))
            )
            .overlay(ShellHUDBrackets(accent: accent))
    }
}

struct ShellHUDBrackets: View {
    let accent: Color
    var length: CGFloat = 14
    var line: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                bracket(at: CGPoint(x: 0, y: 0), hFlip: false, vFlip: false, w: w, h: h)
                bracket(at: CGPoint(x: w, y: 0), hFlip: true, vFlip: false, w: w, h: h)
                bracket(at: CGPoint(x: 0, y: h), hFlip: false, vFlip: true, w: w, h: h)
                bracket(at: CGPoint(x: w, y: h), hFlip: true, vFlip: true, w: w, h: h)
            }
        }
        .allowsHitTesting(false)
    }

    private func bracket(at origin: CGPoint, hFlip: Bool, vFlip: Bool, w: CGFloat, h: CGFloat) -> some View {
        Path { p in
            let x = origin.x
            let y = origin.y
            let dx: CGFloat = hFlip ? -length : length
            let dy: CGFloat = vFlip ? -length : length
            p.move(to: CGPoint(x: x, y: y + dy))
            p.addLine(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + dx, y: y))
        }
        .stroke(accent.opacity(0.75), lineWidth: line)
    }
}

// MARK: - Mission hero banner

struct ShellForgeHeroBanner: View {
    let imageName: String
    let title: String
    let subtitle: String
    let accent: Color
    var height: CGFloat = 168

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55), .black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            ShellScanlineOverlay(accent: accent, opacity: 0.06)

            VStack(alignment: .leading, spacing: 4) {
                ShellMetallicTitle(text: title, size: 20, accent: accent)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(0.7))
                    .tracking(2)
            }
            .padding(14)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(colors: [accent.opacity(0.5), accent.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: accent.opacity(0.2), radius: 16, y: 6)
    }
}

struct ShellScanlineOverlay: View {
    let accent: Color
    var opacity: Double = 0.08

    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(line, with: .color(accent.opacity(opacity)), lineWidth: 0.5)
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Avatar chip

typealias ShellArcReactorCore = ShellCoreEngine

struct ShellAvatarChip: View {
    let imageName: String
    let accent: Color
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: size + 8, height: size + 8)
                .blur(radius: 6)
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(accent.opacity(0.6), lineWidth: 1.5))
                .shadow(color: accent.opacity(0.35), radius: 10)
        }
    }
}
