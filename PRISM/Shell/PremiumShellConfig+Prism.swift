import SwiftUI

extension PremiumShellConfig {
    /// Canon: CORTEX_APP_BREAKDOWN.html — Communication Layer · #a855f7
    static let prism = PremiumShellConfig(
        appKind: .prism,
        displayName: "PRISM",
        alias: "PRISM",
        ecosystemSubtitle: "PRISM is the publisher.",
        roleLine: "Write it once. Reach every platform.",
        identityLine: "Draft your content. Approve it. Publish to connected accounts.",
        orbLabel: "PRISM CORE",
        primaryActionTitle: "Create Post",
        primaryModuleId: "signal_composer",
        accent: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
        accentDeep: Color(red: 126 / 255, green: 34 / 255, blue: 206 / 255),
        refractionAccent: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
        refractionPink: Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255),
        introHeroImageName: "PRISMIntroHero",
        introVideoResourceName: "prism_intro_godmode",
        introTaglineTop: "THE PUBLISHER",
        introTaglineAlias: "PRISM",
        introTaglineBottom: "CREATE · APPROVE · PUBLISH",
        introStatusTitle: "DRAFT STUDIO",
        storagePrefix: "prism.shell",
        modules: [
            ShellModuleDefinition(id: "signal_composer", title: "Create Post", subtitle: "Write and save your draft locally", icon: "waveform.path", availability: .preview),
            ShellModuleDefinition(id: "platform_outputs", title: "Platform Versions", subtitle: "Tailor your post for each platform", icon: "square.stack.3d.up.fill", availability: .preview),
            ShellModuleDefinition(id: "refraction_preview", title: "Preview on Each Platform", subtitle: "See how it looks before you post", icon: "arrow.triangle.branch", availability: .preview),
            ShellModuleDefinition(id: "campaign_calendar", title: "Campaign Calendar", subtitle: "Plan when to post", icon: "calendar", availability: .preview),
            ShellModuleDefinition(id: "brand_voice", title: "Brand Voice", subtitle: "Keep your tone consistent", icon: "text.quote", availability: .preview),
            ShellModuleDefinition(id: "audience_selector", title: "Choose Your Audience", subtitle: "Pick who you are talking to", icon: "person.3.fill", availability: .preview),
            ShellModuleDefinition(id: "draft_queue", title: "Draft Queue", subtitle: "Review before anything goes live", icon: "tray.full.fill", availability: .preview),
            ShellModuleDefinition(id: "distribution_status", title: "Publishing Status", subtitle: "Nothing is live until you approve it", icon: "arrow.triangle.branch", availability: .preview),
            ShellModuleDefinition(id: "proof_assets", title: "Screenshots & Proof", subtitle: "Save what you created", icon: "doc.richtext.fill", availability: .preview),
            ShellModuleDefinition(id: "image_studio", title: "Image Studio", subtitle: "Create and save visuals locally", icon: "photo.on.rectangle.angled", availability: .preview),
            ShellModuleDefinition(id: "approval_gate", title: "Review Before Posting", subtitle: "Nothing posts without your sign-off", icon: "checkmark.seal.fill", availability: .preview),
            ShellModuleDefinition(id: "audit_trail", title: "Activity Log", subtitle: "Everything you have done, saved locally", icon: "list.bullet.rectangle.fill", availability: .preview),
        ],
        topologyTitle: "Platform Map",
        topologyHubLabel: "PRISM",
        topologyNodes: [
            ShellTopologyNode(name: "Your Content", status: "Draft saved locally", offsetX: -78, offsetY: -20),
            ShellTopologyNode(name: "CORTEX Core", status: "Connects later", offsetX: 0, offsetY: -70),
            ShellTopologyNode(name: "Platforms", status: "Connect to publish", offsetX: 78, offsetY: -20),
            ShellTopologyNode(name: "Your Approval", status: "Required before posting", offsetX: 0, offsetY: 72),
        ],
        supportEmailPlaceholder: "support@cortexnode.ai",
        monthlyPriceDisplay: "Preview · App Store setup pending",
        freeTierDisplay: "Free: Full draft studio · local saves · approval gate",
        aiDisclaimer: "PRISM drafts content for your approval. Nothing publishes without explicit sign-off. Not therapy or professional advice.",
        barTabs: [.command, .channels, .modules, .studio, .settings, .about]
    )
}
