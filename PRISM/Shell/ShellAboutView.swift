import SwiftUI

/// PRISM About screen — app identity, version, and the publishing policy the App Store
/// review notes require this tab to display (no auto-posting; approval-gated; broadcast
/// only to connected accounts). Restored after the prior definition was removed while its
/// call site in PremiumShellRouter remained, which broke the build.
private struct ShellAboutSection<Content: View>: View {
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

struct ShellAboutView: View {
    @Bindable var env: ShellEnvironment

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        let palette = env.palette
        let config = env.config

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header(palette: palette, config: config)

                ShellAboutSection(title: "What PRISM Is", palette: palette) {
                    aboutLine("A multi-channel draft studio. Write one source signal, refract it into platform-specific drafts, approve, then publish only to accounts you connect.", palette)
                }

                ShellAboutSection(title: "Publishing Policy", palette: palette) {
                    policyRow("No auto-posting", "Nothing leaves this device without your explicit Approve + Broadcast.", palette)
                    policyRow("Approval gate", "Every draft passes through the Approval Gate before it can be queued to publish.", palette)
                    policyRow("Connected accounts only", "Broadcast is available only for platforms you connect in Channels. Unconnected platforms show \"Not connected\" and never post.", palette)
                    policyRow("You own the data", "Drafts and connections stay under your control. PRISM is the publisher — no third-party middleman.", palette)
                }

                ShellAboutSection(title: "Support", palette: palette) {
                    aboutLine("support@cortexnode.ai", palette)
                    aboutLine("cortexnode.ai", palette)
                }

                Text(versionLine)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(palette.textSecondary)
                    .padding(.top, 4)

                Text("© 2026 CORTEXNODE INC.")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(palette.textSecondary.opacity(0.7))
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func header(palette: ShellThemePalette, config: PremiumShellConfig) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("About")
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
                .accessibilityIdentifier("prism-about-title")
            Text(config.displayName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func aboutLine(_ text: String, _ palette: ShellThemePalette) -> some View {
        Text(text)
            .font(palette.captionFont)
            .foregroundColor(palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func policyRow(_ title: String, _ detail: String, _ palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(palette.textPrimary)
            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
