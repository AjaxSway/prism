import SwiftUI

extension PremiumShellConfig {
    /// Canon: CORTEX_APP_BREAKDOWN.html — Communication Layer · #a855f7
    static let prism = PremiumShellConfig(
        appKind: .prism,
        displayName: "PRISM",
        alias: "SIGNAL",
        ecosystemSubtitle: "The Interface · Communication Layer",
        roleLine: "How the system speaks to the world.",
        identityLine: "One signal in. Every channel out. One voice.",
        orbLabel: "PRISM CORE",
        primaryActionTitle: "Create Signal",
        primaryModuleId: "signal_composer",
        accent: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
        accentDeep: Color(red: 126 / 255, green: 34 / 255, blue: 206 / 255),
        refractionAccent: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
        refractionPink: Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255),
        introHeroImageName: "PRISMIntroHero",
        introTaglineTop: "THE INTERFACE",
        introTaglineAlias: "PRISM",
        introTaglineBottom: "COMMUNICATION LAYER · SHELL PREVIEW",
        introStatusTitle: "PRISM READY",
        storagePrefix: "prism.shell",
        modules: [
            ShellModuleDefinition(id: "signal_composer", title: "Signal Composer", subtitle: "Draft-only · Create Signal", icon: "waveform.path", availability: .preview),
            ShellModuleDefinition(id: "platform_outputs", title: "Platform Outputs", subtitle: "Refraction Preview · 8 channels", icon: "square.stack.3d.up.fill", availability: .preview),
            ShellModuleDefinition(id: "campaign_calendar", title: "Campaign Calendar", subtitle: "Schedule preview", icon: "calendar", availability: .preview),
            ShellModuleDefinition(id: "brand_voice", title: "Brand Voice", subtitle: "Tone · proof · consistency", icon: "text.quote", availability: .preview),
            ShellModuleDefinition(id: "draft_queue", title: "Draft Queue", subtitle: "Approval required", icon: "tray.full.fill", availability: .preview),
            ShellModuleDefinition(id: "distribution_status", title: "Distribution Status", subtitle: "No live publishing", icon: "arrow.triangle.branch", availability: .preview),
            ShellModuleDefinition(id: "proof_assets", title: "Proof Assets", subtitle: "Screenshots · audit line", icon: "doc.richtext.fill", availability: .preview),
            ShellModuleDefinition(id: "approval_gate", title: "Approval Gate", subtitle: "Nothing posts without sign-off", icon: "checkmark.seal.fill", availability: .preview),
        ],
        topologyTitle: "Refraction Map",
        topologyHubLabel: "PRISM",
        topologyNodes: [
            ShellTopologyNode(name: "Signal In", status: "Draft-only", offsetX: -78, offsetY: -20),
            ShellTopologyNode(name: "CORTEX Core", status: "Connect later", offsetX: 0, offsetY: -70),
            ShellTopologyNode(name: "Platforms", status: "Not connected", offsetX: 78, offsetY: -20),
            ShellTopologyNode(name: "Approval Gate", status: "Required", offsetX: 0, offsetY: 72),
        ],
        supportEmailPlaceholder: "support@cortexnode.ai",
        monthlyPriceDisplay: "$59.99/mo",
        freeTierDisplay: "Free: Draft preview · 1 channel placeholder",
        aiDisclaimer: "PRISM drafts content for your approval. Nothing publishes without explicit sign-off. Not therapy or professional advice.",
        barTabs: [.command, .modules, .activity, .studio, .settings, .about]
    )
}
