import SwiftUI

struct ShellAboutView: View {
    let config: PremiumShellConfig
    let palette: ShellThemePalette

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("About & Trust")
                    .font(palette.titleFont)
                    .foregroundColor(palette.textPrimary)
                    .padding(.top, 12)

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
                    title: "Brain wiring (Claude / Adam)",
                    bullets: brainWireBullets
                )

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
            .padding(.bottom, 24)
        }
        .background(ShellScreenBackground(palette: palette))
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
                "Draft-only signal composer and refraction preview.",
                "Platform outputs staged per channel — no live publishing.",
                "Brand voice, campaign calendar, and approval gate mock.",
                "Image Studio UI — generate disabled until brain connects.",
            ]
        }
    }

    private var brainWireBullets: [String] {
        let gate = ShellFeatureFlags.brainConnected ? "brainConnected = true" : "brainConnected = false (preview)"
        switch config.appKind {
        case .cortexNode:
            return [
                "Flip \(gate) in ShellFeatureFlags.swift after api.cortexnode.ai verified.",
                "Wire ShellBrainGateway.connect() + node registry routes.",
                "Populate System Map / Node Health from /v1/nodes (create route).",
                "See CLAUDE_BRAIN_WIRE.md in repo (not bundled).",
            ]
        case .jericho:
            return [
                "Flip \(gate) · wire trust events to JerichoAuditLogger bridge.",
                "Permission gate + policy guardrails from governance OS.",
                "Risk review scoring — advisory API, no fake LIVE labels.",
                "See CLAUDE_BRAIN_WIRE.md in repo (not bundled).",
            ]
        case .prism:
            return [
                "Flip \(gate) · wire draft queue + OAuth per platform (server-side).",
                "Image Studio: ShellImageGenerationService.generate() route.",
                "Approval gate must block publish until operator sign-off.",
                "See CLAUDE_BRAIN_WIRE.md in repo (not bundled).",
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
    }
}
