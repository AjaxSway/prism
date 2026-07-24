import SwiftUI

private struct ShellSettingsSection<Content: View>: View {
    let title: String
    let palette: ShellThemePalette
    @ViewBuilder var content: Content

    var body: some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased())
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                content
            }
        }
    }
}

struct ShellSettingsView: View {
    @Bindable var env: ShellEnvironment
    @Bindable private var music = ShellIntroMusic.shared
    @Bindable private var voicePrefs = ShellVoicePreferences.shared
    @State private var isConnecting = false

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private var brainStatusLabel: String {
        if !ShellFeatureFlags.brainConnected { return "Shell preview · Super Brain connect later" }
        return env.brain.statusDetail
    }

    private var brainStatusTone: ShellStatusBadge.Tone {
        switch env.brain.state {
        case .connected: return .success
        case .error, .offline: return .warning
        case .connecting, .preview: return .neutral
        }
    }

    private var brainStatusCopy: String {
        if !ShellFeatureFlags.brainConnected {
            return "Local draft studio stays on device. Super Brain routing is disabled in this build."
        }
        switch env.brain.state {
        case .connected:
            return "PRISM lens active · api.cortexnode.ai/v1/chat · approval required before publish."
        case .connecting:
            return "Establishing session with CORTEX backbone…"
        case .error, .offline:
            return "Super Brain route unavailable. Draft studio and local modules still work. Retry from Command or probe here."
        case .preview:
            return "Shell preview · first command attempts Super Brain route when enabled."
        }
    }

    var body: some View {
        let palette = env.palette
        let config = env.config

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if config.appKind == .prism {
                    HStack(spacing: 14) {
                        ShellPrismCoreOrb(
                            violet: config.refractionAccent ?? palette.accent,
                            pink: config.refractionPink ?? config.accentDeep,
                            size: 44,
                            intensity: 0.95,
                            orbState: env.orbState
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(palette.titleFont)
                                .foregroundColor(palette.textPrimary)
                            Text("Draft studio · local controls · honest connectivity")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 12)
                } else {
                    Text("Settings")
                        .font(palette.titleFont)
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                }

                ShellSettingsSection(title: "Trust & Control", palette: palette) {
                    Text("You control memory, connections, and account data.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    legalRow("Privacy Policy", url: ShellLegalLinks.privacy, palette: palette)
                    legalRow("Terms of Service", url: ShellLegalLinks.terms, palette: palette)
                    legalRow("AI Safety Notice", url: ShellLegalLinks.aiSafety, palette: palette)
                    legalRow("Security", url: ShellLegalLinks.security, palette: palette)
                }

                ShellSettingsSection(title: "CORTEX Super Brain", palette: palette) {
                    ShellStatusBadge(
                        text: brainStatusLabel,
                        palette: palette,
                        tone: brainStatusTone
                    )
                    Text(brainStatusCopy)
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if ShellFeatureFlags.brainConnected {
                        Button {
                            Task { await env.brain.connect(appKind: env.config.appKind) }
                        } label: {
                            Text(env.brain.state == .connected ? "RE-CHECK BRAIN ROUTE" : "PROBE SUPER BRAIN ROUTE")
                                .font(palette.captionFont)
                                .foregroundColor(palette.accent)
                        }
                        .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                    }
                }

                ShellSettingsSection(title: "Subscription", palette: palette) {
                    ShellStatusBadge(text: "Free tier active", palette: palette, tone: .success)
                    Text("Pro \(config.monthlyPriceDisplay) · unlocks when App Store IAP is configured.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    Text(config.freeTierDisplay)
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    Button { env.showSubscriptionPlans = true } label: {
                        Text("VIEW PLANS")
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                    // Guideline 3.1.1 fix: these three links pointed straight to
                    // cortexnode.ai's real, live, purchasable-via-website pricing
                    // page — a working $19.99/mo checkout with no Apple IAP
                    // equivalent in this app. Confirmed via Apple's own review
                    // screenshots on JERICHO (shared Settings code): tap Plans &
                    // Pricing → real external checkout. No app in this Shell
                    // family has a working Apple IAP right now (zero products
                    // registered in App Store Connect) — no legitimate reason to
                    // advertise a paid upgrade path that isn't purchasable
                    // through Apple.
                    Button {
                        Task {
                            await CortexStoreManager.shared.restorePurchases()
                            env.showToast("Purchases Restored", detail: "Your subscription status has been updated.", tone: .info)
                        }
                    } label: {
                        Text("RESTORE PURCHASES")
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                    .accessibilityIdentifier("prism-restore-purchases")
                }

                ShellSettingsSection(title: "Account", palette: palette) {
                    Text("Manage account and deletion at cortexnode.ai.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    legalRow("Delete Account", url: ShellLegalLinks.accountDeletion, palette: palette)
                    legalRow("Contact Support", url: ShellLegalLinks.support, palette: palette)
                }

                ShellSettingsSection(title: "Voice", palette: palette) {
                    Toggle(isOn: $voicePrefs.speakResponsesEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-speak brain responses")
                                .font(palette.bodyFont.weight(.semibold))
                                .foregroundColor(palette.textPrimary)
                            Text("Off by default · uses CORTEX voice route when session is available")
                                .font(.system(size: 10))
                                .foregroundColor(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(palette.accent)
                    Text(voicePrefs.lastPlaybackStatus)
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        Task { _ = await VoiceService.speakWithStatus("PRISM voice route check. Draft only until you approve.") }
                    } label: {
                        Text("TEST VOICE ROUTE")
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                    .accessibilityIdentifier("prism-test-voice")
                }

                ShellSettingsSection(title: "Sound", palette: palette) {
                    Toggle(isOn: $music.isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Background music")
                                .font(palette.bodyFont.weight(.semibold))
                                .foregroundColor(palette.textPrimary)
                            Text(
                                ShellIntroMusic.isRunningOnSimulator
                                    ? "Off in Simulator · use your iPhone for theme audio"
                                    : "CORTEXNODE.ai theme · loops while you use the app"
                            )
                                .font(.system(size: 10))
                                .foregroundColor(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(palette.accent)
                    .disabled(ShellIntroMusic.isRunningOnSimulator)
                }

                ShellSettingsSection(title: "Visual Mode", palette: palette) {
                    HStack(spacing: 10) {
                        themeCard(title: "Futuristic", subtitle: "HUD · core glow · scanlines", theme: .futuristic, palette: palette)
                        themeCard(title: "Classy", subtitle: "Executive glass · calm motion", theme: .classy, palette: palette)
                    }
                }

                ShellSettingsSection(title: "System Intro", palette: palette) {
                    Button {
                        let key = AppIntroConfig.forShell(config).defaultsKey
                        UserDefaults.standard.set(false, forKey: key)
                        env.showToast("Intro reset", detail: "Force-quit and reopen to replay the cinematic intro.", tone: .info)
                    } label: {
                        Text("REPLAY SYSTEM INTRO")
                            .font(palette.captionFont)
                            .foregroundColor(palette.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                ShellSettingsSection(title: "Diagnostics", palette: palette) {
                    Text(versionLine).font(palette.captionFont).foregroundColor(palette.textPrimary)
                    Text(env.shellStatusLine).font(palette.captionFont).foregroundColor(palette.textSecondary)
                    Text(config.aiDisclaimer).font(.system(size: 10)).foregroundColor(palette.textSecondary)
                }

                Button { env.resetMockData() } label: {
                    Text("RESET LOCAL DRAFT DATA")
                        .font(palette.captionFont)
                        .foregroundColor(palette.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(palette.backgroundElevated)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.glassStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 180)
        }
        .background(ShellAmbientBackground(palette: palette, accentOverride: env.config.refractionAccent, intensity: 0.45, theme: env.theme, appKind: env.config.appKind == .prism ? .prism : nil))
    }

    private func legalRow(_ title: String, url: URL, palette: ShellThemePalette) -> some View {
        Link(destination: url) {
            HStack {
                Text(title).font(palette.bodyFont).foregroundColor(palette.accent)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundColor(palette.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func themeCard(title: String, subtitle: String, theme: ShellVisualTheme, palette: ShellThemePalette) -> some View {
        let preview = ShellThemePalette.palette(for: theme, accent: env.config.accent)
        let selected = env.theme == theme
        return Button { env.theme = theme } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [preview.background, preview.accent.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 54)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? preview.accent : preview.glassStroke, lineWidth: selected ? 2 : 1))
                Text(title).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(palette.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
