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
    @State private var isConnecting = false
    @State private var restoreMessage: String?

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        let palette = env.palette
        let config = env.config
        let brain = env.brain

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text("Settings")
                    .font(palette.titleFont)
                    .foregroundColor(palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)

                ShellSettingsSection(title: "Trust & Control", palette: palette) {
                    Text("You control memory, connections, and account data.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    legalRow("Privacy Policy", url: ShellLegalLinks.privacy, palette: palette)
                    legalRow("Terms of Service", url: ShellLegalLinks.terms, palette: palette)
                    legalRow("AI Safety Notice", url: ShellLegalLinks.aiSafety, palette: palette)
                    legalRow("Security", url: ShellLegalLinks.security, palette: palette)
                }

                ShellSettingsSection(title: "Brain Connection", palette: palette) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(brain.state.rawValue.uppercased())
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(brain.isLive ? palette.accent : palette.warning)
                            Text(brain.statusDetail)
                                .font(palette.captionFont)
                                .foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        if ShellFeatureFlags.brainConnected {
                            Button(isConnecting ? "…" : "Connect") {
                                Task {
                                    isConnecting = true
                                    await brain.connect(appKind: config.appKind)
                                    isConnecting = false
                                }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.accent)
                            .disabled(isConnecting)
                        }
                    }
                    if !ShellFeatureFlags.brainConnected {
                        Text("Preview build · Claude enables brainConnected when api.cortexnode.ai is verified.")
                            .font(.system(size: 10))
                            .foregroundColor(palette.textSecondary)
                    }
                }

                ShellSettingsSection(title: "Subscription", palette: palette) {
                    Text(config.monthlyPriceDisplay)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(palette.accent)
                    Text(config.freeTierDisplay)
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    legalRow("Plans & Pricing", url: ShellLegalLinks.pricing, palette: palette)
                    legalRow("Subscription Terms", url: ShellLegalLinks.subscriptionTerms, palette: palette)
                    legalRow("Refund Policy", url: ShellLegalLinks.refundPolicy, palette: palette)
                    Button {
                        Task {
                            do {
                                try await ShellPreviewSubscriptionService().restorePurchases()
                            } catch {
                                restoreMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("RESTORE PURCHASES")
                            .font(palette.captionFont)
                            .foregroundColor(palette.textSecondary)
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.system(size: 10))
                            .foregroundColor(palette.warning)
                    }
                }

                ShellSettingsSection(title: "Account", palette: palette) {
                    Text("Operator account surface connects with CORTEX backbone.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    legalRow("Delete Account", url: ShellLegalLinks.accountDeletion, palette: palette)
                    legalRow("Contact Support", url: ShellLegalLinks.support, palette: palette)
                }

                ShellSettingsSection(title: "Visual Mode", palette: palette) {
                    HStack(spacing: 10) {
                        themeCard(title: "Futuristic", subtitle: "HUD · core glow · scanlines", theme: .futuristic, palette: palette)
                        themeCard(title: "Classy", subtitle: "Executive glass · calm motion", theme: .classy, palette: palette)
                    }
                }

                ShellSettingsSection(title: "Diagnostics", palette: palette) {
                    Text(versionLine).font(palette.captionFont).foregroundColor(palette.textPrimary)
                    Text(env.shellStatusLine).font(palette.captionFont).foregroundColor(palette.textSecondary)
                    Text(config.aiDisclaimer).font(.system(size: 10)).foregroundColor(palette.textSecondary)
                }

                Button { env.resetMockData() } label: {
                    Text("RESET LOCAL PREVIEW DATA")
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
            .padding(.bottom, 24)
        }
        .background(ShellAmbientBackground(palette: palette, theme: env.theme))
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
                Text(subtitle).font(.system(size: 9)).foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(palette.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
