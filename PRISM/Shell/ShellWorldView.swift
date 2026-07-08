import SwiftUI

/// WORLD — Global intelligence dashboard (CORTEX Public parity).
struct ShellWorldView: View {
    let env: ShellEnvironment

    @State private var animateIn = false
    @State private var infoMessage: String?

    private var accent: Color { env.palette.accent }
    private var green: Color { env.palette.success }
    private var warning: Color { .orange }
    private var routeLive: Bool { env.brain.isLive }

    var body: some View {
        ZStack {
            env.palette.background.ignoresSafeArea()
            RadialGradient(
                colors: [accent.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.12),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    worldHeader
                        .padding(.horizontal, 18)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    worldDashboard
                        .padding(.horizontal, 18)

                    worldActionFooter
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                }
                .padding(.bottom, 148)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { animateIn = true }
        }
        .alert("WORLD", isPresented: Binding(
            get: { infoMessage != nil },
            set: { if !$0 { infoMessage = nil } }
        )) {
            Button("GOT IT", role: .cancel) { infoMessage = nil }
        } message: {
            Text(infoMessage ?? "")
        }
    }

    // MARK: - Header

    private var worldHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WORLD")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .top, endPoint: .bottom))
                    .shadow(color: accent.opacity(0.5), radius: 14)

                Text("GLOBAL INTEL • WEATHER • TRAVEL")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(accent.opacity(0.65))
                    .tracking(3)

                HStack(spacing: 14) {
                    subNav("GLOBAL INTEL", active: true) { infoMessage = "Reference intel preview for this shell surface." }
                    subNav("WEATHER") { openURL("weather://") }
                    subNav("TRAVEL") { infoMessage = "Travel planning preview. Live routing connects when brain route is proven." }
                }
                .padding(.top, 2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 5) {
                    Circle().fill(routeLive ? green : warning).frame(width: 6, height: 6)
                    Text(routeLive ? "RELAY OK" : "LOCAL")
                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                        .foregroundStyle((routeLive ? green : warning).opacity(0.9))
                }
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.7), radius: 10)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 14)
    }

    // MARK: - Dashboard

    private var worldDashboard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Button { openURL("maps://") } label: { dotMapCard }.buttonStyle(.plain)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    metricCard("newspaper.fill", "WORLD BRIEF", "PREVIEW", "REFERENCE INTEL", accent) {
                        infoMessage = "Reference intel preview for \(env.config.alias)."
                    }
                    metricCard("cloud.sun.bolt.fill", "WEATHER", "LOCAL OFF", "CONNECT LOCATION", Color(red: 0.35, green: 0.78, blue: 0.98)) {
                        openURL("weather://")
                    }
                    metricCard("airplane", "TRAVEL", "PREVIEW", "PLANNING MODE", Color(red: 0.55, green: 0.45, blue: 1.0)) {
                        infoMessage = "Travel planning preview on this device."
                    }
                    metricCard("exclamationmark.triangle.fill", "ALERTS", "NONE", "NO LIVE FEED", warning) {
                        infoMessage = "No live global alert feed is connected in this preview build."
                    }
                }
            }

            HStack(alignment: .top, spacing: 10) {
                globeHero
                compactMapCard
            }

            VStack(spacing: 12) {
                HStack {
                    Text("GLOBAL BRIEFING")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7))
                        .tracking(2)
                    Spacer()
                    Text("REFERENCE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                briefingRow("dot.radiowaves.left.and.right", "REGIONAL WATCH", "Americas stable. Europe stable. Asia Pacific monitoring.", accent)
                briefingRow("airplane.departure", "AIR • TRAFFIC • WEATHER", "Air quality and travel feeds are local-preview until connected.", Color(red: 0.55, green: 0.45, blue: 1.0))
                briefingRow("shield.checkered", "TRUST STATUS", "No global live-feed claim is active from this screen.", green)
            }
            .padding(14)
            .background(panel)

            HStack(spacing: 0) {
                stat("5", "REGIONS", accent)
                stat("PREVIEW", "DATA", green)
                stat(routeLive ? "CHAT" : "LOCAL", "ROUTE", Color(red: 0.35, green: 0.78, blue: 0.98))
            }
            .padding(.vertical, 10)
            .background(panel)
        }
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var worldActionFooter: some View {
        HStack(spacing: 10) {
            footerBtn("OPEN MAP", "map.fill", accent) { openURL("maps://") }
            footerBtn("WORLD BRIEF", "newspaper.fill", Color(red: 0.35, green: 0.78, blue: 0.98)) {
                infoMessage = "Reference intel preview for \(env.config.alias)."
            }
            footerBtn("ALERTS", "exclamationmark.triangle.fill", warning) {
                infoMessage = "No live global alert feed is connected."
            }
        }
        .opacity(animateIn ? 1 : 0)
    }

    // MARK: - Components

    private var dotMapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.38), lineWidth: 1))
            ShellWorldDotMap(accent: accent, green: green, warning: warning)
                .padding(10)
            VStack {
                HStack {
                    Text("GLOBAL MAP")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7))
                    Spacer()
                }
                .padding(10)
                Spacer()
                HStack(spacing: 8) {
                    legend(accent, "CORTEX NODE")
                    legend(green, "ROUTE")
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    private var globeHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.38), lineWidth: 1))
            VStack(spacing: 6) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [accent, Color(red: 0.35, green: 0.78, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("GLOBAL INTEL")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(accent.opacity(0.85))
                    .tracking(3)
            }
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 128)
    }

    private var compactMapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [.black, Color(red: 0.01, green: 0.04, blue: 0.08)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.48), lineWidth: 1))
            CortexRealWorldMapView(accent: accent, positive: green)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack {
                HStack {
                    Text("GLOBAL MAP")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accent.opacity(0.7))
                    Spacer()
                    Circle().fill(routeLive ? green : warning).frame(width: 5, height: 5)
                }
                .padding(10)
                Spacer()
                HStack(spacing: 8) {
                    legend(accent, "NODE")
                    legend(green, "ROUTE")
                    legend(warning, "HUB")
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 128)
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(red: 0.04, green: 0.07, blue: 0.12).opacity(0.92))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.18), lineWidth: 0.8))
    }

    private func metricCard(_ icon: String, _ title: String, _ value: String, _ subtitle: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundStyle(tint.opacity(0.88)).lineLimit(1).minimumScaleFactor(0.7)
                Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(tint)
                Text(value).font(.system(size: 13, weight: .black, design: .monospaced)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 6, weight: .bold, design: .monospaced)).foregroundStyle(Color.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.03, green: 0.06, blue: 0.11).opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.38), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private func briefingRow(_ icon: String, _ title: String, _ body: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(tint)
                .frame(width: 34, height: 34).background(Circle().fill(tint.opacity(0.14)))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 12, weight: .heavy, design: .monospaced)).foregroundStyle(.white)
                Text(body).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.03, green: 0.05, blue: 0.10).opacity(0.82)))
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .black, design: .monospaced)).foregroundStyle(color)
            Text(label).font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundStyle(color.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundStyle(color.opacity(0.8))
        }
    }

    private func subNav(_ title: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(active ? accent : Color.white.opacity(0.45))
                .underline(active, color: accent.opacity(0.6))
        }
        .buttonStyle(.plain)
    }

    private func footerBtn(_ title: String, _ icon: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(tint)
                Text(title).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.white.opacity(0.88))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Dot map canvas

private struct ShellWorldDotMap: View {
    let accent: Color
    let green: Color
    let warning: Color

    var body: some View {
        Canvas { context, size in
            let cols = 40, rows = 18
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)
            let mapBits = [
                "0000011111100000001111100001100000110000",
                "0001111111100001111111100011110001111000",
                "0001111111110001111111100011111011111100",
                "0001111111111001111111110011111111111100",
                "0000111111111001111111111011111111111100",
                "0000011111111000111111111011111111111000",
                "0000001111110000011111100011111111100000",
                "0000000111100000001111100001111111000000",
                "0000000011100000001000000001111110000000",
                "0000000001000000000000000000111100000000",
                "0000000000000000000000000000010000000000",
                "0000000000000000001000000000000000000000",
                "0000000000000000011100000000000000000000",
                "0000000000000000011110000000000000000000",
                "0000000000000000001100000000000000000000",
            ]
            for (row, line) in mapBits.enumerated() {
                for (col, char) in line.enumerated() where char == "1" {
                    let x = CGFloat(col) * cellW + cellW / 2
                    let y = CGFloat(row) * cellH + cellH / 2
                    context.fill(Path(ellipseIn: CGRect(x: x - 1.25, y: y - 1.25, width: 2.5, height: 2.5)), with: .color(accent.opacity(0.55)))
                }
            }
            let hubs: [(Int, Int)] = [(8, 4), (18, 5), (27, 5), (32, 4), (14, 7), (22, 10)]
            let pts = hubs.map { CGPoint(x: CGFloat($0.0) * cellW + cellW / 2, y: CGFloat($0.1) * cellH + cellH / 2) }
            for point in pts.dropFirst() {
                var arc = Path()
                arc.move(to: pts[0])
                arc.addQuadCurve(to: point, control: CGPoint(x: (pts[0].x + point.x) / 2, y: min(pts[0].y, point.y) - 40))
                context.stroke(arc, with: .color(green.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
            }
            for (i, point) in pts.enumerated() {
                let color = i == 0 ? accent : (i % 3 == 0 ? warning : green)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(color))
            }
        }
    }
}
