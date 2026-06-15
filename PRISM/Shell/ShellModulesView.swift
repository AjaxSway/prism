import SwiftUI

struct ShellModulesView: View {
    @Bindable var env: ShellEnvironment
    @State private var selectedModule: ShellModuleDefinition?
    @State private var openedModule: ShellModuleDefinition?

    var body: some View {
        let palette = env.palette
        let config = env.config

        NavigationStack {
            ZStack {
                ShellAmbientBackground(palette: palette, theme: env.theme)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("Modules")
                            .font(palette.titleFont)
                            .foregroundColor(palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)

                        if selectedModule?.id == config.primaryModuleId || selectedModule == nil {
                            topologyPreview(palette: palette, config: config)
                        }

                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                            ForEach(config.modules) { module in
                                Button {
                                    selectedModule = module
                                    openedModule = module
                                    env.activityStore.append(
                                        title: "Module opened",
                                        detail: "\(module.title) · \(module.subtitle)",
                                        kind: .navigation
                                    )
                                } label: {
                                    ShellModuleCard(module: module, palette: palette)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(item: $openedModule) { module in
                ShellModuleDetailView(module: module, env: env)
            }
        }
        .onAppear {
            if selectedModule == nil {
                selectedModule = config.modules.first
            }
            consumePendingModuleOpen()
        }
        .onChange(of: env.pendingModuleOpen?.id) { _, _ in
            consumePendingModuleOpen()
        }
    }

    private func consumePendingModuleOpen() {
        guard let pending = env.pendingModuleOpen else { return }
        selectedModule = pending
        openedModule = pending
        env.pendingModuleOpen = nil
    }

    private func topologyPreview(palette: ShellThemePalette, config: PremiumShellConfig) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(config.topologyTitle)
                        .font(palette.bodyFont.weight(.semibold))
                        .foregroundColor(palette.textPrimary)
                    Spacer()
                    ShellStatusBadge(text: "Mock topology", palette: palette)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(palette.background.opacity(0.6))
                        .frame(height: 200)

                    Canvas { ctx, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        for node in config.topologyNodes {
                            let pt = CGPoint(x: center.x + node.offsetX, y: center.y + node.offsetY)
                            var line = Path()
                            line.move(to: center)
                            line.addLine(to: pt)
                            ctx.stroke(line, with: .color(palette.accent.opacity(0.25)), lineWidth: 1)
                        }
                        let hubDot = CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)
                        ctx.fill(Path(ellipseIn: hubDot), with: .color(palette.offline))
                        for node in config.topologyNodes {
                            let pt = CGPoint(x: center.x + node.offsetX, y: center.y + node.offsetY)
                            let dot = CGRect(x: pt.x - 6, y: pt.y - 6, width: 12, height: 12)
                            ctx.fill(Path(ellipseIn: dot), with: .color(palette.offline))
                        }
                    }
                    .frame(height: 200)
                }

                VStack(alignment: .leading, spacing: 6) {
                    mapRow(config.topologyHubLabel, "Offline preview", palette: palette, online: false)
                    ForEach(config.topologyNodes) { node in
                        mapRow(node.name, node.status, palette: palette, online: false)
                    }
                }

                Text("Topology preview only. Live registry wiring comes after approval.")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
            }
        }
    }

    private func mapRow(_ name: String, _ status: String, palette: ShellThemePalette, online: Bool) -> some View {
        HStack {
            Circle()
                .fill(online ? palette.accent : palette.offline)
                .frame(width: 6, height: 6)
            Text(name)
                .font(palette.captionFont)
                .foregroundColor(palette.textPrimary)
            Spacer()
            Text(status)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
    }
}
