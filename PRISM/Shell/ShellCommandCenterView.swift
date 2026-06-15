import SwiftUI

struct ShellCommandCenterView: View {
    @Bindable var env: ShellEnvironment
    @State private var commandText = ""
    @State private var previewText = "Stage a command or tap a quick action."
    @State private var resultText = "Results appear here."
    @State private var showApproval = false
    @State private var isRunning = false

    private var quickActions: [String] {
        switch env.config.appKind {
        case .cortexNode:
            return ["System Map", "Node Health", "Data Flow", "Sync Status"]
        case .jericho:
            return ["Trust Check", "Permission Gate", "Boundary Rule", "Audit Trail"]
        case .prism:
            return ["Draft Signal", "Channel Pack", "Schedule Preview", "Approval Gate"]
        }
    }

    var body: some View {
        let palette = env.palette
        let brain = env.brain

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if env.config.appKind == .cortexNode {
                    nodeCommandHeader(palette: palette)
                } else if env.config.appKind == .jericho {
                    jerichoCommandHeader(palette: palette)
                } else if env.config.appKind == .prism {
                    prismCommandHeader(palette: palette)
                } else {
                    Text("Command Center")
                        .font(palette.titleFont)
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }

                ShellStatusBadge(
                    text: brain.isLive ? "Brain connected · Approval required for risky actions" : "Preview · Execution gated until brain connects",
                    palette: palette,
                    tone: brain.isLive ? .success : .warning
                )
                .padding(.horizontal, 20)

                ShellHUDBracketPanel(accent: palette.accent) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("COMMAND INPUT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textSecondary)
                        TextField("Ask \(env.config.displayName)…", text: $commandText, axis: .vertical)
                            .font(palette.bodyFont)
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(3...6)
                        Button { Task { await runCommand() } } label: {
                            HStack {
                                if isRunning { ProgressView().scaleEffect(0.8) }
                                Text(isRunning ? "RUNNING…" : (brain.isLive ? "SEND TO BRAIN" : "PREVIEW MOCK"))
                                    .font(palette.captionFont)
                            }
                            .foregroundColor(palette.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
                    }
                }
                .padding(.horizontal, 20)

                quickActionRow(palette: palette)
                panel(title: "Preview", text: previewText, palette: palette)
                panel(title: "Approval Gate", text: approvalLine, palette: palette)
                panel(title: "Result", text: resultText, palette: palette)

                ShellAuditStrip(palette: palette, line: "All commands logged · \(env.config.aiDisclaimer)")
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .background(ShellScreenBackground(palette: palette))
    }

    @ViewBuilder
    private func nodeCommandHeader(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Operator Control Center")
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ShellCanonIntegrationEcosystemView(accent: palette.accent, height: 140)
            ShellCanonControlCenterStrip(accent: palette.accent)
            ShellCanonDataFlowLanesView(accent: palette.accent, height: 72)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func jerichoCommandHeader(palette: ShellThemePalette) -> some View {
        let red = env.config.accent
        let blue = Color(red: 0.2, green: 0.75, blue: 0.95)
        VStack(alignment: .leading, spacing: 14) {
            Text("Trust Command Center")
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
            ShellCanonJerichoProtectionView(red: red, blue: blue, height: 120)
            ShellCanonJerichoPillarsView(red: red, blue: blue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func prismCommandHeader(palette: ShellThemePalette) -> some View {
        let violet = env.config.refractionAccent ?? palette.accent
        let pink = env.config.refractionPink ?? env.config.accentDeep
        VStack(alignment: .leading, spacing: 14) {
            Text("Refraction Command Center")
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
            ShellCanonPrismCommunicationGridView(violet: violet, pink: pink, height: 140)
            ShellCanonAdaptiveFlowView(accent: violet, height: 64)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var approvalLine: String {
        if showApproval { return "Approval required before publish, sync, or deploy actions." }
        return "No risky action staged."
    }

    private func quickActionRow(palette: ShellThemePalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickActions, id: \.self) { action in
                    Button {
                        commandText = action
                        Task { await runCommand() }
                    } label: {
                        Text(action)
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(palette.backgroundElevated)
                            .overlay(Capsule().stroke(palette.glassStroke, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func panel(title: String, text: String, palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased()).font(palette.captionFont).foregroundColor(palette.textSecondary)
                Text(text).font(palette.bodyFont).foregroundColor(palette.textPrimary)
            }
        }
        .padding(.horizontal, 20)
    }

    private func runCommand() async {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isRunning = true
        env.orbState = .thinking
        previewText = trimmed
        showApproval = ["publish", "sync", "deploy", "blast", "post"].contains { trimmed.lowercased().contains($0) }

        var output = ""
        do {
            let stream = await env.brain.stream(prompt: trimmed, appKind: env.config.appKind)
            for try await chunk in stream {
                output += chunk
                resultText = output
            }
            env.orbState = showApproval ? .warning : .success
        } catch {
            resultText = error.localizedDescription
            env.orbState = .error
        }

        env.activityStore.append(title: "Command", detail: trimmed, kind: .command)
        isRunning = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { env.orbState = .idle }
    }
}
