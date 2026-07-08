import SwiftUI

// MARK: - NODE module views (master shell)

struct NodeSystemMapView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("System Map", "Living ecosystem · Seven apps · Not connected", palette: palette)
            ShellStatusBadge(text: "Mock topology · Shell Preview", palette: palette)
            ShellLivingEcosystemMapView(accent: palette.accent, height: 360)
            ShellCanonSevenLayersView(accent: palette.accent)
            topologyRows(palette: palette, config: env.config)
        }
    }
}

struct NodeHealthView: View {
    @Bindable var env: ShellEnvironment

    private let metrics: [(String, Double, Color)] = [
        ("Network", 0.0, Color(red: 0.4, green: 0.7, blue: 1)),
        ("Sync", 0.0, Color(red: 0.58, green: 0.64, blue: 0.72)),
        ("Brain Link", 0.0, Color(red: 0.3, green: 0.95, blue: 0.6)),
        ("Registry", 0.0, Color(red: 0.98, green: 0.68, blue: 0.12))
    ]

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Node Health", "Offline preview · No live telemetry", palette: palette)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics, id: \.0) { m in
                    ShellCircularGauge(label: m.0, value: m.1, accent: m.2)
                    .overlay(alignment: .bottom) {
                        Text("Not connected")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(palette.textSecondary)
                            .padding(.bottom, 4)
                    }
                }
            }
            ShellAuditStrip(palette: palette, line: "Health metrics populate when brain connects · Connect later")
        }
    }
}

struct NodeConnectedAppsView: View {
    @Bindable var env: ShellEnvironment

    private let apps = [
        ("CORTEX", "Connect later", Color(red: 0, green: 0.78, blue: 0.95)),
        ("Signal Zero", "Offline preview", Color(red: 0.13, green: 0.83, blue: 0.93)),
        ("JERICHO", "Not connected", Color(red: 0.94, green: 0.27, blue: 0.27)),
        ("PRISM", "Not connected", Color(red: 0.66, green: 0.33, blue: 0.97)),
        ("FORGE", "Not connected", Color(red: 0.98, green: 0.68, blue: 0.12)),
        ("ATLAS", "Not connected", Color(red: 0.13, green: 0.78, blue: 0.45))
    ]

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Connected Apps", "Ecosystem surfaces · Shell registry preview", palette: palette)
            ForEach(apps, id: \.0) { app in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Circle().fill(app.2.opacity(0.35)).frame(width: 10, height: 10)
                        Text(app.0).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                        Spacer()
                        Text(app.1).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                    }
                }
            }
        }
    }
}

struct NodeDataFlowView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Data Flow", "Inputs → NODE → outputs · Mock lanes", palette: palette)
            ShellCanonAdaptiveFlowView(accent: palette.accent, height: 80)
            ShellCanonDataFlowLanesView(accent: palette.accent, height: 160)
            ForEach(["CORTEX Brain", "Device Events", "API Connectors", "Operator Console"], id: \.self) { lane in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Text(lane).font(palette.captionFont).foregroundColor(palette.textPrimary)
                        Spacer()
                        ShellStatusBadge(text: "Preview", palette: palette)
                    }
                }
            }
        }
    }
}

struct NodeDeviceLinksView: View {
    @Bindable var env: ShellEnvironment

    private let devices = [
        ("iPhone", "This device · Shell preview"),
        ("Mac", "Connect later"),
        ("Watch", "Connect later"),
        ("iPad", "Connect later")
    ]

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Device Links", "One body · one network · offline preview", palette: palette)
            ForEach(devices, id: \.0) { d in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Image(systemName: d.0 == "Watch" ? "applewatch" : "iphone")
                            .foregroundColor(palette.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.0).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                            Text(d.1).font(.system(size: 9)).foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

struct NodeEcosystemOverviewView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Ecosystem Overview", "Five layers · one brain · mock map", palette: palette)
            ShellCanonFiveLayersView(accent: palette.accent)
            ShellCanonIntegrationEcosystemView(accent: palette.accent, height: 180)
            Text("CORTEXNODE is the connective tissue between intelligence, execution, protection, and communication.")
                .font(.system(size: 11))
                .foregroundColor(palette.textSecondary)
        }
    }
}

struct NodeAccountSurfaceView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Account Surface", "Operator identity · Connect later", palette: palette)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("OPERATOR").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(palette.textSecondary)
                    Text("Shell preview account")
                        .font(palette.bodyFont.weight(.semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("Sign-in and sync wiring lands after brain connection.")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                }
            }
            ShellPrimaryButton(title: "Connect Account", palette: palette) {
                env.presentConnectLater(
                    "Operator Account",
                    detail: "Sign-in and sync activate when CORTEX backbone connects. Shell preview uses a local mock identity.",
                    steps: [
                        "Sign in to CORTEX once to seed session keys.",
                        "Connect brain from Settings in this app.",
                        "Account surface syncs operator profile and audit trail.",
                    ]
                )
            }
        }
    }
}

struct NodeSyncStatusView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 14) {
            nodeHeader("Sync Status", "No live sync · Offline preview", palette: palette)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    syncRow("Brain backbone", "Not connected", palette: palette)
                    syncRow("Device registry", "Not connected", palette: palette)
                    syncRow("Topology cache", "Local mock", palette: palette)
                    syncRow("Activity log", "Local only", palette: palette)
                }
            }
        }
    }

    private func syncRow(_ name: String, _ status: String, palette: ShellThemePalette) -> some View {
        HStack {
            Circle().fill(palette.offline).frame(width: 6, height: 6)
            Text(name).font(palette.captionFont).foregroundColor(palette.textPrimary)
            Spacer()
            Text(status).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
        }
    }
}

private func nodeHeader(_ title: String, _ subtitle: String, palette: ShellThemePalette) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title.uppercased())
            .font(palette.titleFont)
            .foregroundColor(palette.textPrimary)
        Text(subtitle)
            .font(.system(size: 11))
            .foregroundColor(palette.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private func topologyRows(palette: ShellThemePalette, config: PremiumShellConfig) -> some View {
    ShellGlassPanel(palette: palette) {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(config.topologyNodes) { node in
                HStack {
                    Circle().fill(palette.offline).frame(width: 6, height: 6)
                    Text(node.name).font(palette.captionFont).foregroundColor(palette.textPrimary)
                    Spacer()
                    Text(node.status).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                }
            }
        }
    }
}
