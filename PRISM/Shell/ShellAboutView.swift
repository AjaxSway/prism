import SwiftUI

struct ShellAboutView: View {
    let config: PremiumShellConfig
    let palette: ShellThemePalette
    var brain: ShellBrainGateway?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if config.appKind == .prism {
                    PrismTrustHeroBanner(config: config, palette: palette, orbState: .idle)
                }

                Text("About & Trust")
                    .font(palette.titleFont)
                    .foregroundColor(palette.textPrimary)
                    .padding(.top, 12)
                    .accessibilityIdentifier("prism-about-title")

                ShellHUDBracketPanel(accent: palette.accent) {
                    VStack(alignment: .leading, spacing: 8) {
                        ShellMetallicTitle(text: config.displayName, size: 18, accent: palette.accent)
                        Text(config.ecosystemSubtitle)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent.opacity(0.65))
                        Text(config.identityLine)
                            .font(palette.bodyFont)
                            .foregroundColor(palette.textPrimary)
                            .padding(.top, 4)
                    }
                }

                trustBlock(
                    title: "What \(config.displayName) does",
                    bullets: capabilityBullets
                )

                trustBlock(
                    title: "What requires your control",
                    bullets: [
                        "Approval gates for publishing and risky commands.",
                        "Account deletion via Settings → Delete Account.",
                        "Memory and connectors managed in Trust & Control Center.",
                    ]
                )

                trustBlock(
                    title: "Connectivity & services",
                    bullets: connectivityBullets
                )

                if config.appKind == .prism, let brain {
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CORTEX Super Brain").font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                            ShellStatusBadge(
                                text: ShellFeatureFlags.brainConnected ? brain.statusDetail : "Shell preview · connect later",
                                palette: palette,
                                tone: brain.state == .connected ? .success : .warning
                            )
                            Text("PRISM lens · draft-only · operator approval required before publish.")
                                .font(.system(size: 10))
                                .foregroundColor(palette.textSecondary)
                        }
                    }
                }

                trustBlock(
                    title: "AI & professional use",
                    bullets: [
                        config.aiDisclaimer,
                        "Not medical, legal, financial, emergency, or licensed trade advice.",
                        "Important decisions should be verified independently.",
                    ]
                )

                trustBlock(
                    title: "Legal",
                    bullets: []
                )
                VStack(spacing: 8) {
                    aboutLink("Privacy Policy", ShellLegalLinks.privacy)
                    aboutLink("Terms of Service", ShellLegalLinks.terms)
                    aboutLink("AI Safety Notice", ShellLegalLinks.aiSafety)
                    aboutLink("Account Deletion", ShellLegalLinks.accountDeletion)
                }

                ShellAuditStrip(palette: palette, line: "CORTEXNODE Inc. · \(config.supportEmailPlaceholder)")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 180)
        }
        .background(ShellScreenBackground(palette: palette, appKind: config.appKind == .prism ? .prism : nil))
    }

    private var capabilityBullets: [String] {
        switch config.appKind {
        case .cortexNode:
            return [
                "Preview system map, node health, and ecosystem topology.",
                "Connected surfaces registry and data-flow lanes (mock-only).",
                "Device links and sync status — offline until brain connects.",
                "Operator control center — no live telemetry in shell preview.",
            ]
        case .jericho:
            return [
                "Trust check, permission gate, and boundary rule previews.",
                "Audit trail and risk review — advisory only, offline mock.",
                "Policy guardrails and alert review — connect later.",
                "Not antivirus. Not a guarantee of safety or compliance.",
            ]
        case .prism:
            return [
                "Signal composer with local save and refraction across social channels.",
                "Draft queue, approval gate, campaign calendar, and audit trail on device.",
                "Image Studio with preset gallery, share export, and proof attach.",
                "DRAFT ONLY · APPROVAL REQUIRED · no live platform publish today.",
            ]
        }
    }

    private var connectivityBullets: [String] {
        switch config.appKind {
        case .cortexNode:
            return [
                "System map, node health, and registry populate when CORTEX backbone connects.",
                "Device links and sync status remain offline in this shell preview.",
                "No live telemetry or fake connected labels in preview builds.",
            ]
        case .jericho:
            return [
                "Trust checks, audit trail, and policy guardrails connect later.",
                "Advisory previews only — not antivirus or device-wide protection.",
                "Permission gates require operator approval before risky actions go live.",
            ]
        case .prism:
            return [
                "All drafts, images, and audit events persist locally on your iPhone.",
                "Super Brain routes through api.cortexnode.ai when session is available.",
                "Share and export use the system share sheet — no cloud publish without approval.",
                "Nothing posts to social platforms without your explicit sign-off.",
            ]
        }
    }

    private func trustBlock(title: String, bullets: [String]) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundColor(palette.accentSoft)
                        Text(bullet).font(palette.captionFont).foregroundColor(palette.textSecondary)
                    }
                }
            }
        }
    }

    private func aboutLink(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title).font(palette.captionFont).foregroundColor(palette.accent)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 10))
            }
        }
        .accessibilityIdentifier(config.appKind == .prism ? "prism-about-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))" : "about-link")
    }
}
