import SwiftUI

/// HOME — CORTEX Universe radial command hub: character pills, intel strip,
/// and an orbiting module ring around a central pulsing core.
/// Matches the CORTEX god-mode HUD look, minus the founder-only status chips.
struct ShellRadialHomeView: View {
    @Bindable var env: ShellEnvironment
    @State private var orbitAngle: Double = 0
    @State private var pulse = false

    private var accent: Color { env.palette.accent }
    private var secondary: Color { env.config.refractionPink ?? env.config.accentDeep }

    var body: some View {
        let palette = env.palette
        let config = env.config

        ZStack {
            Color.black.ignoresSafeArea()
            if palette.usesNeuralMesh { ShellNeuralMeshBackground(accent: accent) }
            if palette.usesScanlines { ShellScanlineOverlay(accent: accent, opacity: 0.045) }
            ShellAmbientBackground(palette: palette, accentOverride: accent, intensity: 0.5, theme: env.theme, appKind: config.appKind)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header(config: config)
                    characterPillsRow
                    intelRow
                    orbitRing(config: config)
                    ShellPrimaryButton(title: config.primaryActionTitle, palette: palette) {
                        env.openPrimaryModule()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { orbitAngle = 360 }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    // MARK: - Header

    private func header(config: PremiumShellConfig) -> some View {
        VStack(spacing: 2) {
            ShellMetallicTitle(text: config.displayName, size: 30, accent: accent)
            Text(config.ecosystemSubtitle.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(accent.opacity(0.6))
                .tracking(1.8)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Character pills

    private var characterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(NexusUniverseNode.all.prefix(6))) { node in
                    let isSelf = node.id == env.config.appKind.homeNodeID
                    Text(node.name)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(isSelf ? .black : node.color)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(isSelf ? node.color : node.color.opacity(0.12)))
                        .overlay(Capsule().stroke(node.color.opacity(isSelf ? 0 : 0.4), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Intel row

    private var intelRow: some View {
        let recent = env.activityStore.events.first
        return HStack(spacing: 10) {
            intelCard(icon: "doc.text.fill", label: "DIGEST", value: "\(env.activityStore.events.count) LOGGED")
            intelCard(icon: "dot.radiowaves.left.and.right", label: "SITREP", value: recent?.title ?? "Standing by")
            intelCard(icon: "waveform.path.ecg", label: "READY", value: env.orbState == .offline ? "OFFLINE" : "\(Int(pulse ? 100 : 96))%")
        }
    }

    private func intelCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 9)).foregroundColor(accent)
                Text(label).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(accent.opacity(0.8)).tracking(0.5)
            }
            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(env.palette.textPrimary.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.backgroundElevated)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.15), lineWidth: 0.8)))
    }

    // MARK: - Orbit ring

    private func orbitRing(config: PremiumShellConfig) -> some View {
        let modules = config.modules
        let ringRadius: CGFloat = 128
        let ringSize: CGFloat = ringRadius * 2 + 90

        return ZStack {
            Circle().stroke(accent.opacity(0.15), lineWidth: 1).frame(width: ringRadius * 2, height: ringRadius * 2)
            Circle().stroke(accent.opacity(0.08), lineWidth: 1).frame(width: ringRadius * 2 + 40, height: ringRadius * 2 + 40)

            ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                let angle = (Double(index) / Double(max(modules.count, 1))) * 360 - 90
                let rad = angle * .pi / 180
                let x = cos(rad) * ringRadius
                let y = sin(rad) * ringRadius
                orbitNode(module: module)
                    .offset(x: x, y: y)
            }

            ShellAppCoreOrbView(
                appKind: config.appKind,
                color: accent,
                secondary: secondary,
                size: 108,
                intensity: pulse ? 1.05 : 0.9,
                orbState: env.orbState
            )
            .onTapGesture { env.demoOrbCycle() }
        }
        .frame(width: ringSize, height: ringSize)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func orbitNode(module: ShellModuleDefinition) -> some View {
        Button {
            env.openModule(module)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(Color.black.opacity(0.85)).frame(width: 52, height: 52)
                    Circle().stroke(accent.opacity(0.5), lineWidth: 1.2).frame(width: 52, height: 52)
                    Image(systemName: module.icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(accent)
                }
                .shadow(color: accent.opacity(0.35), radius: 8)
                Text(module.title.uppercased())
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(env.palette.textPrimary.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 68)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension ShellAppKind {
    var homeNodeID: String { rawValue.lowercased() }
}
