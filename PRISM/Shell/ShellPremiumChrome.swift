import SwiftUI

// MARK: - Neural pulse (shell-local, CORTEX-inspired)

enum ShellNeuralPulseMode {
    case idle, active, speaking

    var ringCount: Int {
        switch self {
        case .idle: return 2
        case .active: return 3
        case .speaking: return 4
        }
    }

    var duration: Double {
        switch self {
        case .idle: return 3.2
        case .active: return 1.6
        case .speaking: return 1.1
        }
    }

    var maxOpacity: Double {
        switch self {
        case .idle: return 0.18
        case .active: return 0.32
        case .speaking: return 0.42
        }
    }
}

struct ShellNeuralPulseView: View {
    let color: Color
    var mode: ShellNeuralPulseMode = .idle
    var maxRadius: CGFloat = 48

    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<mode.ringCount, id: \.self) { i in
                let offset = CGFloat(i) / CGFloat(mode.ringCount)
                let progress = fmod(phase + offset, 1.0)
                Circle()
                    .stroke(color.opacity(Double(1 - progress) * mode.maxOpacity), lineWidth: 1.2)
                    .frame(width: maxRadius * 2 * progress, height: maxRadius * 2 * progress)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: mode.duration).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
        .allowsHitTesting(false)
    }
}

struct ShellNeuralMeshBackground: View {
    let accent: Color
    @State private var drift = false

    var body: some View {
        Canvas { ctx, size in
            let nodes: [CGPoint] = (0..<14).map { i in
                let x = size.width * CGFloat((Double(i * 17 % 100)) / 100.0)
                let y = size.height * CGFloat((Double(i * 29 % 100)) / 100.0)
                return CGPoint(x: x, y: y)
            }
            for i in 0..<nodes.count {
                for j in (i + 1)..<nodes.count where (i + j).isMultiple(of: 3) {
                    var path = Path()
                    path.move(to: nodes[i])
                    path.addLine(to: nodes[j])
                    ctx.stroke(path, with: .color(accent.opacity(0.08)), lineWidth: 0.6)
                }
                let r: CGFloat = 2
                let dot = CGRect(x: nodes[i].x - r, y: nodes[i].y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: dot), with: .color(accent.opacity(0.22)))
            }
        }
        .opacity(drift ? 0.9 : 0.65)
        .blur(radius: 0.3)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) { drift = true }
        }
        .allowsHitTesting(false)
    }
}

struct ShellFloatingHubOrb: View {
    let label: String
    let appKind: ShellAppKind
    let secondaryColor: Color
    let state: ShellOrbState
    let palette: ShellThemePalette
    var isActive: Bool
    var onTap: () -> Void

    private var stateColor: Color { palette.orbColor(for: state) }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isActive {
                    PrismPulseRing(color: stateColor, secondary: secondaryColor, diameter: 68, speed: 1.35)
                }

                Circle()
                    .fill(Color.black.opacity(0.88))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(isActive ? stateColor.opacity(0.9) : stateColor.opacity(0.35), lineWidth: isActive ? 2 : 1.2)
                    )
                    .shadow(color: stateColor.opacity(isActive ? 0.35 : 0.15), radius: isActive ? 12 : 6)

                ShellCortexBrainPulseView(
                    color: stateColor,
                    visual: ShellBrainPulseVisual.from(orbState: state),
                    appKind: appKind,
                    secondaryColor: secondaryColor,
                    size: 52,
                    showGlyph: true
                )
                .clipShape(Circle())
            }
            .overlay(alignment: .bottom) {
                Text(label)
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .offset(y: 16)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(appKind == .prism ? "prism-tab-home" : "\(appKind)-hub-orb")
    }
}

struct ShellHUDTabBar: View {
    @Binding var selection: ShellTab
    let palette: ShellThemePalette
    let tabs: [ShellTab]
    var appKind: ShellAppKind = .cortexNode

    var body: some View {
        HStack(spacing: 0) {
            if appKind == .prism {
                let left: [ShellTab] = [.command, .channels, .modules].filter { tabs.contains($0) }
                let right: [ShellTab] = [.studio, .settings, .about].filter { tabs.contains($0) }
                tabGroup(left)
                Color.clear.frame(width: 58).accessibilityHidden(true)
                tabGroup(right)
            } else {
                tabGroup(tabs)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 18).fill(palette.background.opacity(0.42)))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [palette.accent.opacity(0.12), palette.accent.opacity(0.28), palette.accent.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: palette.accent.opacity(0.12), radius: 16, y: 4)
        )
    }

    @ViewBuilder
    private func tabGroup(_ group: [ShellTab]) -> some View {
        HStack(spacing: 0) {
            ForEach(group, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ tab: ShellTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: appKind == .prism ? 17 : 20, weight: .semibold))
                    .foregroundStyle(selection == tab ? palette.accent : palette.textSecondary)
                Text(tab.rawValue.uppercased())
                    .font(.system(size: appKind == .prism ? 8 : 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(selection == tab ? palette.accent : palette.textSecondary.opacity(0.85))
                Capsule()
                    .fill(selection == tab ? palette.accent : .clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tabAccessibilityID(for: tab))
    }

    private func tabAccessibilityID(for tab: ShellTab) -> String {
        switch appKind {
        case .prism: return "prism-tab-\(tab.rawValue.lowercased())"
        case .jericho: return "jericho-tab-\(tab.rawValue.lowercased())"
        case .cortexNode: return "node-tab-\(tab.rawValue.lowercased())"
        }
    }
}

struct ShellGlowToolCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let glow: Color
    let palette: ShellThemePalette
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(glow)
                    .shadow(color: glow.opacity(0.45), radius: 8)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(palette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(14)
            .background(palette.backgroundElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(glow.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ShellSegmentPicker<Item: Hashable & Identifiable>: View {
    let items: [Item]
    @Binding var selection: Item
    let palette: ShellThemePalette
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let icon: (Item) -> String
    let fill: (Item) -> LinearGradient

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { selection = item }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon(item))
                            .font(.system(size: 13, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(title(item))
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                            Text(subtitle(item))
                                .font(.system(size: 9, weight: .medium))
                                .opacity(0.55)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(selection == item ? .black : .white.opacity(0.65))
                    .background(
                        Group {
                            if selection == item {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill(item))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}
