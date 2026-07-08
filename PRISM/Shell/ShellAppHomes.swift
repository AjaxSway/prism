import SwiftUI

// MARK: - Router entry

struct ShellHomeView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        if env.config.appKind == .prism {
            PrismRefractionHome(env: env)
        } else {
            ShellRadialHomeView(env: env)
        }
    }
}

// MARK: - CORTEXNODE · Nervous System Command

struct NodeControlCenterHome: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let config = env.config
        let cyan = config.accent
        let graphite = config.accentDeep

        ZStack {
            Color.black.ignoresSafeArea()
            if env.palette.usesNeuralMesh { ShellNeuralMeshBackground(accent: cyan) }
            if env.palette.usesScanlines { ShellScanlineOverlay(accent: cyan, opacity: 0.045) }
            ShellAmbientBackground(palette: palette, accentOverride: cyan, intensity: 0.55, theme: env.theme, appKind: .cortexNode)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            ShellMetallicTitle(text: config.displayName, size: 24, accent: cyan)
                            Text("THE NERVOUS SYSTEM · PLATFORM COMMAND")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(cyan.opacity(0.65))
                                .tracking(1.8)
                        }
                        Spacer()
                        ShellStatusBadge(text: "Shell Preview", palette: palette)
                    }

                    ShellNervousSystemDeck(
                        accent: cyan,
                        secondary: graphite,
                        orbState: env.orbState,
                        onOrbTap: { env.demoOrbCycle() }
                    )

                    ShellPrimaryButton(title: config.primaryActionTitle, palette: palette) {
                        env.openPrimaryModule()
                    }

                    nodeHealthPreview(palette: palette, accent: cyan, graphite: graphite)

                    ShellCanonSectionHeader(
                        title: "Living Ecosystem Map",
                        subtitle: "CORTEX · Signal Zero · JERICHO · PRISM · FORGE · ATLAS · mock topology",
                        accent: cyan
                    )
                    ShellLivingEcosystemMapView(accent: cyan, height: 340)

                    ShellCanonSectionHeader(
                        title: "Data Flow Lanes",
                        subtitle: "Inputs → NODE → outputs · mock topology only",
                        accent: cyan
                    )
                    ShellCanonAdaptiveFlowView(accent: cyan, height: 72)

                    ShellCanonSectionHeader(
                        title: "Platform Surfaces",
                        subtitle: "System map · health · apps · flow · devices · sync · account",
                        accent: cyan
                    )
                    nodePlatformSurfacesStrip(env: env, palette: palette, accent: cyan)

                    ShellCanonSectionHeader(
                        title: "Seven Layers · One Universe",
                        subtitle: "CORTEX ecosystem stack · offline preview",
                        accent: cyan
                    )
                    ShellCanonSevenLayersView(accent: cyan)

                    ShellAuditStrip(palette: palette, line: "Mock topology · Not connected · Connect later · Mock data only")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
    }

    private func nodePlatformSurfacesStrip(env: ShellEnvironment, palette: ShellThemePalette, accent: Color) -> some View {
        let ids = ["system_map", "node_health", "connected_apps", "data_flow", "device_links", "sync_status", "account_surface", "ecosystem_overview"]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ids, id: \.self) { id in
                if let module = env.config.modules.first(where: { $0.id == id }) {
                    ShellForgeModuleTile(
                        title: module.title,
                        subtitle: module.subtitle,
                        icon: module.icon,
                        accent: accent,
                        palette: palette
                    ) {
                        env.openModule(module)
                    }
                }
            }
        }
    }
}

// MARK: - JERICHO · Immune Vault

struct JerichoShieldHome: View {
    @Bindable var env: ShellEnvironment
    private let red = Color(red: 0.937, green: 0.267, blue: 0.267)
    private let steel = Color(red: 0.2, green: 0.75, blue: 0.95)
    private let amber = Color(red: 0.98, green: 0.68, blue: 0.12)

    var body: some View {
        let palette = env.palette

        ZStack {
            Color.black.ignoresSafeArea()
            if env.palette.usesScanlines { ShellScanlineOverlay(accent: red, opacity: 0.05) }
            ShellAmbientBackground(palette: palette, accentOverride: red, intensity: 0.52, theme: env.theme, appKind: .jericho)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ShellMetallicTitle(text: "JERICHO", size: 24, accent: red)
                            Text("IMMUNE SYSTEM · TRUST & CONTAINMENT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(red.opacity(0.65))
                                .tracking(1.8)
                        }
                        Spacer()
                        ShellStatusBadge(text: "Advisory only", palette: palette, tone: .warning)
                    }

                    ShellImmuneVaultDeck(
                        red: red,
                        steel: steel,
                        orbState: env.orbState,
                        onOrbTap: { env.demoOrbCycle() }
                    )

                    ShellPrimaryButton(title: env.config.primaryActionTitle, palette: palette) {
                        env.openPrimaryModule()
                    }

                    ShellCanonJerichoPillarsView(red: red, blue: steel)

                    ShellCanonSectionHeader(
                        title: "Trust Surfaces",
                        subtitle: "Permission gates · policy guardrails · audit preview",
                        accent: red
                    )

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        jerichoTile("Trust State", "Advisory preview · Not connected", "checkmark.shield.fill", red, palette) { openJerichoModule("trust_check", env: env) }
                        jerichoTile("Permission Gate", "Approval required", "lock.shield.fill", steel, palette) { openJerichoModule("permission_gate", env: env) }
                        jerichoTile("Boundary Rules", "Policy guardrail", "rectangle.dashed.badge.record", red.opacity(0.85), palette) { openJerichoModule("boundary_rules", env: env) }
                        jerichoTile("Audit Trail", "Offline preview", "list.bullet.rectangle.fill", steel.opacity(0.9), palette) { openJerichoModule("audit_trail", env: env) }
                        jerichoTile("Risk Review", "Advisory scoring", "eye.trianglebadge.exclamationmark.fill", amber, palette) { openJerichoModule("risk_review", env: env) }
                        jerichoTile("Integrity Scan", "Mock checklist only", "shield.lefthalf.filled", red, palette) { openJerichoModule("integrity_scan", env: env) }
                        jerichoTile("Policy Review", "Guardrail cards · Preview", "doc.text.fill", steel, palette) { openJerichoModule("policy_guardrail", env: env) }
                        jerichoTile("Alert Review", "Not connected", "bell.badge.fill", red.opacity(0.75), palette) { openJerichoModule("alert_review", env: env) }
                    }

                    ShellAuditStrip(palette: palette, line: "Trust gate · Advisory only · No antivirus · No device-wide protection claims")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
    }

    private func jerichoTile(_ title: String, _ subtitle: String, _ icon: String, _ accent: Color, _ palette: ShellThemePalette, action: @escaping () -> Void) -> some View {
        ShellForgeModuleTile(title: title, subtitle: subtitle, icon: icon, accent: accent, palette: palette, action: action)
    }
}

// MARK: - PRISM

struct PrismRefractionHome: View {
    @Bindable var env: ShellEnvironment
    var body: some View { PrismRefractionStudioView(env: env) }
}

// MARK: - CORTEXNODE health + topology (mock-only)

private struct nodeHealthPreview: View {
    let palette: ShellThemePalette
    let accent: Color
    let graphite: Color

    var body: some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("NODE HEALTH")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(accent.opacity(0.85))
                    Spacer()
                    ShellStatusBadge(text: "Offline preview", palette: palette)
                }
                HStack(spacing: 0) {
                    healthCell("Sync", "—", accent: accent)
                    healthCell("Latency", "—", accent: graphite)
                    healthCell("Registry", "Mock", accent: accent)
                }
                Text("No live telemetry · No fake health pings · Connect later")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(palette.textSecondary)
            }
        }
    }

    private func healthCell(_ label: String, _ value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(accent.opacity(0.75))
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(accent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Shared helpers

@MainActor
private func openJerichoModule(_ id: String, env: ShellEnvironment) {
    if let module = env.config.modules.first(where: { $0.id == id }) {
        env.openModule(module)
    }
}
