import SwiftUI

// MARK: - CORTEXNODE · Living ecosystem map (seven-app nervous system)

struct ShellLivingEcosystemMapView: View {
    let accent: Color
    var height: CGFloat = 340
    var showLegend: Bool = true

    private struct MapNode: Identifiable {
        let id: String
        let name: String
        let role: String
        let status: String
        let color: Color
        let angle: Double
        let orbit: CGFloat
    }

    private let satellites: [MapNode] = [
        MapNode(id: "cortex", name: "CORTEX", role: "Brain", status: "Connect later", color: Color(red: 0, green: 0.78, blue: 0.95), angle: -90, orbit: 0.88),
        MapNode(id: "signal", name: "Signal Zero", role: "Execution", status: "Shell preview", color: Color(red: 0.13, green: 0.83, blue: 0.93), angle: -30, orbit: 0.92),
        MapNode(id: "jericho", name: "JERICHO", role: "Protection", status: "Not connected", color: Color(red: 0.94, green: 0.27, blue: 0.27), angle: 30, orbit: 0.88),
        MapNode(id: "prism", name: "PRISM", role: "Refraction", status: "Not connected", color: Color(red: 0.66, green: 0.33, blue: 0.97), angle: 90, orbit: 0.92),
        MapNode(id: "forge", name: "FORGE", role: "Builder", status: "Not connected", color: Color(red: 0.98, green: 0.68, blue: 0.12), angle: 150, orbit: 0.86),
        MapNode(id: "atlas", name: "ATLAS", role: "Environment", status: "Not connected", color: Color(red: 0.13, green: 0.78, blue: 0.45), angle: 210, orbit: 0.86),
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.05), Color.black, Color(red: 0.02, green: 0.06, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [accent.opacity(0.45), accent.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.2
                        )
                )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pulse = 0.82 + 0.18 * sin(t * 1.6)

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
                    let maxR = min(size.width, size.height) * 0.38

                    // Outer scan ring
                    for ring in 1...3 {
                        let r = maxR * (0.55 + CGFloat(ring) * 0.18)
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .color(accent.opacity(0.06 + Double(ring) * 0.04)),
                            lineWidth: 0.7
                        )
                    }

                    // Hub glow
                    let hubR = maxR * 0.2
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR * 1.8, y: center.y - hubR * 1.8, width: hubR * 3.6, height: hubR * 3.6)),
                        with: .radialGradient(
                            Gradient(colors: [accent.opacity(0.35 * pulse), accent.opacity(0.08), .clear]),
                            center: center, startRadius: 0, endRadius: hubR * 2.4
                        )
                    )

                    // Lanes + particles
                    for (idx, node) in satellites.enumerated() {
                        let a = node.angle * .pi / 180
                        let r = maxR * node.orbit
                        let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.82)

                        var lane = Path()
                        lane.move(to: center)
                        let mid = CGPoint(x: (center.x + pt.x) / 2 + sin(a) * 12, y: (center.y + pt.y) / 2 - cos(a) * 8)
                        lane.addQuadCurve(to: pt, control: mid)
                        ctx.stroke(
                            lane,
                            with: .color(node.color.opacity(0.22 + 0.08 * pulse)),
                            style: StrokeStyle(lineWidth: 1.1, dash: [5, 7], dashPhase: t * 18 + Double(idx) * 4)
                        )

                        let travel = fmod(t * 0.22 + Double(idx) * 0.14, 1.0)
                        let particle = CGPoint(
                            x: center.x + (pt.x - center.x) * travel + sin(a) * 12 * (1 - travel),
                            y: center.y + (pt.y - center.y) * travel - cos(a) * 8 * (1 - travel)
                        )
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: particle.x - 2.5, y: particle.y - 2.5, width: 5, height: 5)),
                            with: .color(node.color.opacity(0.75))
                        )

                        let nodeR: CGFloat = 7 + CGFloat(pulse) * 2
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: pt.x - nodeR, y: pt.y - nodeR, width: nodeR * 2, height: nodeR * 2)),
                            with: .radialGradient(
                                Gradient(colors: [.white.opacity(0.85), node.color, node.color.opacity(0.35)]),
                                center: pt, startRadius: 0, endRadius: nodeR
                            )
                        )
                        ctx.stroke(
                            Path(ellipseIn: CGRect(x: pt.x - nodeR - 3, y: pt.y - nodeR - 3, width: (nodeR + 3) * 2, height: (nodeR + 3) * 2)),
                            with: .color(node.color.opacity(0.35)),
                            lineWidth: 0.8
                        )
                    }

                    // Hub core
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: center.x - hubR, y: center.y - hubR, width: hubR * 2, height: hubR * 2)),
                        with: .radialGradient(
                            Gradient(colors: [.white, accent, accent.opacity(0.4)]),
                            center: center, startRadius: 0, endRadius: hubR
                        )
                    )
                }
            }

            // Node labels
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.46)
                let maxR = min(geo.size.width, geo.size.height) * 0.38
                ForEach(satellites) { node in
                    let a = node.angle * .pi / 180
                    let r = maxR * node.orbit * 1.18
                    let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.82)
                    VStack(spacing: 2) {
                        Text(node.name)
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(node.color.opacity(0.95))
                        Text(node.status)
                            .font(.system(size: 6, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.38))
                    }
                    .position(pt)
                }

                VStack(spacing: 2) {
                    Text("CORTEXNODE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                    Text("NERVOUS SYSTEM")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.75))
                }
                .position(center)
            }

            if showLegend {
                VStack {
                    Spacer()
                    HStack {
                        Text("LIVING ECOSYSTEM MAP · MOCK TOPOLOGY")
                            .font(.system(size: 7, weight: .black, design: .monospaced))
                            .foregroundColor(accent.opacity(0.55))
                            .tracking(1.2)
                        Spacer()
                        Text("Not connected")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.32))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(height: height)
        .shadow(color: accent.opacity(0.12), radius: 20, y: 6)
    }
}
