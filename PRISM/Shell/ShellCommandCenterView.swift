import SwiftUI
import UIKit

struct ShellCommandCenterView: View {
    @Bindable var env: ShellEnvironment
    @State private var commandText = ""
    @State private var previewText = "Stage a command or tap a quick action."
    @State private var resultText = "Results appear here."
    @State private var showApproval = false
    @State private var isRunning = false
    @State private var lastFailedPrompt = ""
    @State private var showRetry = false
    @State private var lastSpeakableResult = ""
    @Bindable private var voicePrefs = ShellVoicePreferences.shared

    private var quickActions: [String] {
        switch env.config.appKind {
        case .cortexNode:
            return ["System Map", "Node Health", "Data Flow", "Sync Status"]
        case .jericho:
            return ["Trust Check", "Permission Gate", "Boundary Rule", "Audit Trail"]
        case .prism:
            return ["Draft Signal", "Channel Pack", "Schedule", "Approval"]
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
                    text: brainStatusLine(brain: brain),
                    palette: palette,
                    tone: brainStatusTone(brain: brain)
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
                            .accessibilityIdentifier(env.config.appKind == .prism ? "prism-command-field" : "shell-command-field")
                        Button { Task { await runCommand() } } label: {
                            HStack {
                                if isRunning { ProgressView().scaleEffect(0.8) }
                                Text(isRunning ? "RUNNING…" : runButtonTitle(brain: brain))
                                    .font(palette.captionFont)
                            }
                            .foregroundColor(palette.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(env.config.appKind == .prism ? "prism-run-local-draft" : "shell-run-command")
                        .disabled(commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
                    }
                }
                .padding(.horizontal, 20)

                quickActionRow(palette: palette)
                panel(title: "Preview", text: previewText, palette: palette)
                panel(title: "Approval Gate", text: approvalLine, palette: palette)
                panel(title: "Result", text: resultText, palette: palette)

                if !lastSpeakableResult.isEmpty {
                    Button {
                        Task {
                            let ok = await VoiceService.speakWithStatus(String(lastSpeakableResult.prefix(300)))
                            if !ok {
                                env.showToast("Voice unavailable", detail: voicePrefs.lastPlaybackStatus, tone: .warning)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                            Text("HEAR RESPONSE")
                                .font(palette.captionFont)
                        }
                        .foregroundColor(palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(palette.backgroundElevated)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.glassStroke, lineWidth: 1))
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                    .accessibilityIdentifier("prism-hear-response")
                    .padding(.horizontal, 20)
                }

                if showRetry {
                    Button {
                        commandText = lastFailedPrompt
                        Task { await runCommand() }
                    } label: {
                        Text("RETRY SUPER BRAIN ROUTE")
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(palette.backgroundElevated)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.glassStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("prism-retry-brain")
                    .padding(.horizontal, 20)
                }

                ShellAuditStrip(palette: palette, line: "All commands logged · \(env.config.aiDisclaimer)")
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 180)
        }
        .background(ShellScreenBackground(palette: palette, appKind: env.config.appKind == .prism ? .prism : nil))
        .task {
            if ShellFeatureFlags.brainConnected {
                await env.brain.connect(appKind: env.config.appKind)
            }
        }
    }

    @ViewBuilder
    private func nodeCommandHeader(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ShellNetworkCommandStrip(accent: palette.accent, secondary: env.config.accentDeep)
                .padding(.horizontal, 20)
            ShellCanonDataFlowLanesView(accent: palette.accent, height: 64)
                .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func jerichoCommandHeader(palette: ShellThemePalette) -> some View {
        let red = env.config.accent
        let steel = Color(red: 0.2, green: 0.75, blue: 0.95)
        VStack(alignment: .leading, spacing: 14) {
            ShellVaultCommandStrip(red: red, steel: steel)
                .padding(.horizontal, 20)
            ShellCanonJerichoPillarsView(red: red, blue: steel)
                .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func prismCommandHeader(palette: ShellThemePalette) -> some View {
        let violet = env.config.refractionAccent ?? palette.accent
        let pink = env.config.refractionPink ?? env.config.accentDeep
        VStack(alignment: .leading, spacing: 14) {
            ShellRefractionCommandStrip(violet: violet, pink: pink, orbState: env.orbState)
                .padding(.horizontal, 20)
            ShellCanonPrismCommunicationGridView(violet: violet, pink: pink, height: 120)
                .padding(.horizontal, 20)
        }
        .padding(.top, 12)
    }

    private func runButtonTitle(brain: ShellBrainGateway) -> String {
        if ShellFeatureFlags.brainConnected {
            return brain.state == .connected ? "SEND TO SUPER BRAIN" : "TRY SUPER BRAIN ROUTE"
        }
        if env.config.appKind == .prism { return "RUN LOCAL DRAFT" }
        return "RUN LOCAL PREVIEW"
    }

    private var approvalLine: String {
        if showApproval { return "Approval required before publish, sync, or deploy actions." }
        return "No risky action staged."
    }

    private func brainStatusLine(brain: ShellBrainGateway) -> String {
        if !ShellFeatureFlags.brainConnected {
            return env.config.appKind == .prism
                ? "Draft Command Center · Local execution · Super Brain connect later"
                : "Shell preview · Super Brain connect later"
        }
        return brain.statusDetail
    }

    private func brainStatusTone(brain: ShellBrainGateway) -> ShellStatusBadge.Tone {
        switch brain.state {
        case .connected: return .success
        case .error, .offline: return .warning
        case .connecting, .preview: return .neutral
        }
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
        showRetry = false
        env.orbState = .thinking
        previewText = trimmed
        showApproval = ["publish", "sync", "deploy", "blast", "post"].contains { trimmed.lowercased().contains($0) }

        if ShellFeatureFlags.brainConnected {
            do {
                let stream = await env.brain.stream(prompt: trimmed, appKind: env.config.appKind)
                var output = ""
                for try await chunk in stream {
                    output += chunk
                    resultText = output
                    env.orbState = .speaking
                }
                env.orbState = showApproval ? .warning : .success
                lastSpeakableResult = output
                if voicePrefs.speakResponsesEnabled {
                    Task { _ = await VoiceService.speakWithStatus(String(output.prefix(300))) }
                }
                env.activityStore.append(
                    title: "Super Brain response",
                    detail: trimmed.prefix(80).description,
                    kind: .info
                )
                if env.config.appKind == .prism {
                    routePrismModules(trimmed)
                }
            } catch {
                lastFailedPrompt = trimmed
                showRetry = true
                lastSpeakableResult = ""
                if env.config.appKind == .prism {
                    let local = env.runLocalCommand(trimmed)
                    resultText = "Super Brain route unavailable.\n\n\(local)\n\n— Local draft fallback · approval still required"
                    routePrismModules(trimmed)
                } else {
                    resultText = "Super Brain route unavailable. Retry or connect later."
                }
                env.orbState = .error
                env.activityStore.append(
                    title: "Super Brain unavailable",
                    detail: trimmed.prefix(80).description,
                    kind: .warning
                )
            }
        } else if env.config.appKind == .prism {
            try? await Task.sleep(for: .milliseconds(500))
            resultText = env.runLocalCommand(trimmed)
            lastSpeakableResult = resultText
            routePrismModules(trimmed)
            env.orbState = showApproval ? .warning : .success
        } else {
            resultText = "Shell preview · Super Brain connect later."
            lastSpeakableResult = ""
            env.orbState = .offline
        }

        env.activityStore.append(title: "Command", detail: trimmed, kind: .command)
        isRunning = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if env.orbState != .error && env.orbState != .offline { env.orbState = .idle }
        }
    }

    private func routePrismModules(_ trimmed: String) {
        if trimmed.lowercased().contains("draft queue") {
            env.openModule(env.config.modules.first(where: { $0.id == "draft_queue" }) ?? env.config.modules[0])
        }
        if trimmed.lowercased().contains("approval") {
            env.openModule(env.config.modules.first(where: { $0.id == "approval_gate" }) ?? env.config.modules[0])
        }
        if trimmed.lowercased().contains("calendar") || trimmed.lowercased().contains("schedule") {
            env.openModule(env.config.modules.first(where: { $0.id == "campaign_calendar" }) ?? env.config.modules[0])
        }
    }
}
