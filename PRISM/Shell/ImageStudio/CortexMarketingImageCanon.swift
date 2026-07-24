import Foundation

// MARK: - CORTEX MARKETING Image Canon
// Locked visual language from Sir's reference boards (Babies cards, brand sheets,
// God Mode HUDs, pricing heroes, Signal Zero / Atlas / Sovereign / Vehicle UI).
// Used by Image Studio presets + DALL-E style enrichment.

struct CortexMarketingCampaign: Identifiable, Equatable {
    let id: String
    let label: String
    let shortLabel: String
    let aspectRatio: ImageAspectRatio
    let style: ImageStylePreset
    let prompt: String
    let negativePrompt: String
}

enum CortexMarketingImageCanon {

    static let brandLaw = """
    CORTEX MARKETING · God Mode finish. Dark void black / charcoal base. Metallic \
    beveled typography with rim light and controlled bloom. Neon accent lanes only — \
    cyan/ice blue for CORTEX & SIGNAL ZERO, crimson for JERICHO / red God Mode, gold for \
    SOVEREIGN & AURION, violet/magenta for PRISM & Babies, orange for FORGE, green for ATLAS. \
    War-room HUD density: thin frames, status panels, no cartoon clutter, no purple-on-white \
    generic AI look. Premium, cinematic, photoreal materials. Honest status labels only \
    (Preview / Local / Demo — never fake LIVE unless proven).
    """

    static let sharedNegative = """
    stock purple gradient, Inter font, flat white background, cartoonish low-detail, \
    emoji stickers, fake LIVE badges, blurry text, watermark, low resolution, plastic toy look
    """

    static let campaigns: [CortexMarketingCampaign] = [
        CortexMarketingCampaign(
            id: "cortex_brand_sheet",
            label: "CORTEX Brand Sheet",
            shortLabel: "CORTEX Sheet",
            aspectRatio: .landscape,
            style: .cortexBrandSheet,
            prompt: """
            CORTEX brand splash — large metallic beveled CORTEX wordmark centered, cyan core glow \
            inside letters, tagline THE INTELLIGENCE BEHIND YOUR SYSTEMS. Bottom-left HUD panel \
            titled CORTEX // QUICK SHEET with core commands and system info. SIGNAL ZERO watermark \
            bottom-right: NO NOISE. JUST TRUTH. Void black, blue lens flares, scanlines, CORTEX OS v2.4.7.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "signal_zero_sheet",
            label: "SIGNAL ZERO Sheet",
            shortLabel: "S0 Sheet",
            aspectRatio: .landscape,
            style: .signalZeroBlue,
            prompt: """
            SIGNAL ZERO brand splash — heavy metallic SIGNAL ZERO title, ice-blue neon edges, \
            slogan NO NOISE. JUST TRUTH. Ghosted S0 mark in background. Bottom-left SIGNAL ZERO // \
            QUICK SHEET with CORE COMMANDS, SHORTCUTS, SYSTEM INFO. Dark cyber-industrial, particle \
            bloom, CORTEX OS footer CONNECTED style as Preview aesthetic.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "jericho_sheet",
            label: "JERICHO Sheet",
            shortLabel: "JERICHO",
            aspectRatio: .landscape,
            style: .jerichoRed,
            prompt: """
            JERICHO war-room brand sheet — chiseled metallic JERICHO title with crimson neon outline, \
            tagline INTELLIGENCE. PRECISION. DOMINANCE. Red ember particles, threat-level HUD. \
            Bottom-left JERICHO // QUICK SHEET with j- commands. SIGNAL ZERO mark bottom-right. \
            Tactical black metal, red God Mode energy.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "god_mode_blue",
            label: "God Mode Blue HUD",
            shortLabel: "God Mode",
            aspectRatio: .square,
            style: .godModeHUD,
            prompt: """
            CORTEX SIGNAL ZERO GOD MODE circular vault HUD — metallic CORTEX + SIGNAL ZERO + GOD MODE \
            center plate, silver crown with cyan gems, fingerprint lock, corner panels STATUS ONLINE, \
            SYSTEM INTEGRITY 100%, CORE LINK ESTABLISHED. Footer GUARDED. GROUNDED. GRATEFUL. \
            Gunmetal + electric cyan conduits, concentric rings.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "god_mode_red",
            label: "God Mode Red HUD",
            shortLabel: "God Red",
            aspectRatio: .square,
            style: .godModeHUD,
            prompt: """
            CORTEX SIGNAL ZERO GOD MODE hardened red vault HUD — crown with red gems, CORTEX / SIGNAL ZERO / \
            GOD MODE center stack, slogan NO NOISE. JUST TRUTH. Corner widgets SYSTEM STATUS, MAC HUD, \
            INTEGRITY 100%, CORE LINK SECURE AES-256, fingerprint scanner. Crimson circuitry on charcoal metal.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "babies_roster",
            label: "Babies Roster Cards",
            shortLabel: "Babies Grid",
            aspectRatio: .landscape,
            style: .babiesChibi,
            prompt: """
            CORTEX Babies marketing grid — chibi character cards on dark tech circuit backgrounds, \
            each card CORTEX triangle logo + name. Mix of white/blue robots, Signal Zero tactical, \
            Jericho red hood, Prism purple, Aria/Nova/Lyra armored girls, Forge hammer bot, Aurion gold, \
            Atlas globe bot, Guardian sword. High rim light, premium collectible card finish.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "baby_mascot",
            label: "Baby Mascot Hero",
            shortLabel: "Baby Hero",
            aspectRatio: .portrait,
            style: .babiesChibi,
            prompt: """
            Full-body CORTEX Baby robot mascot — pearlescent white armor, charcoal joints, glowing blue \
            visor eyes and crescent smile, concentric blue chest core, standing on reflective dark platform \
            with holographic floor rings. Cute chibi proportions, studio God Mode lighting, bokeh deep blue bg.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "babies_app_marketing",
            label: "Babies App Marketing",
            shortLabel: "Babies App",
            aspectRatio: .portrait,
            style: .babiesChibi,
            prompt: """
            CORTEX BABIES Interactive AI Companions marketing poster — gold geometric title, tagline \
            THEY LEARN. THEY CARE. THEY REMEMBER. Four iPhone mockups showing companion roster, chat, \
            care pedestal, customization. Fluffy cyber companions with glowing chests. Dark blue premium \
            layout, App Store CTA strip, PRIVATE. SECURE. BUILT FOR REAL CONNECTION.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "sovereign_poster",
            label: "SOVEREIGN Poster",
            shortLabel: "Sovereign",
            aspectRatio: .portrait,
            style: .sovereignGold,
            prompt: """
            CORTEX SOVEREIGN vertical poster — waist-up cyber-imperial figure, obsidian armor with gold trim, \
            crown, glowing cyan eyes, blue energy seams, circular halo of data rings. Gold wordmark SOVEREIGN, \
            tagline COMMAND. CONTINUITY. CONTROL. Vertical dark code rain atmosphere.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "aurion_command",
            label: "AURION Command",
            shortLabel: "AURION",
            aspectRatio: .portrait,
            style: .aurionGoldRed,
            prompt: """
            AURION gold-and-red armored command figure — polished gold plates, red slit eyes, glowing red \
            chest reactor, flanking red holographic world-map HUDs, dark war-room grid floor. Authoritative \
            front pose, championship intelligence aesthetic.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "pricing_universe",
            label: "Pricing Universe",
            shortLabel: "Pricing",
            aspectRatio: .landscape,
            style: .pricingHero,
            prompt: """
            CORTEX pricing landing CHOICE YOUR CORTEX — five neon-bordered plan cards Free Pro Operator Elite \
            Sovereign on starfield/nebula dark UI. Lower racks for SIGNAL ZERO CLI, ATLAS BUSINESS OS, \
            CORTEX BABIES. Metallic blue headline, monthly toggle, war-room marketing density, premium SaaS.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "universe_layers",
            label: "Universe Layers",
            shortLabel: "Layers",
            aspectRatio: .portrait,
            style: .pricingHero,
            prompt: """
            CORTEX Personal Intelligence OS marketing — ONE BRAIN. ENDLESS POSSIBILITIES. Neural head silhouette, \
            plan tier row, specialized layers SIGNAL ZERO PRISM JERICHO FORGE AURION ATLAS BABIES as neon modules, \
            how-it-works core diagram, GET STARTED CTA. Dark futuristic modular landing page composition.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "tesla_command",
            label: "Vehicle Command UI",
            shortLabel: "Tesla UI",
            aspectRatio: .landscape,
            style: .vehicleCommand,
            prompt: """
            CORTEX Vehicle Command Center marketing triptych — cinematic Tesla night charge shot, polished \
            iPhone mockup with battery climate lock sentry, detail battery wireframe green pack + live power \
            chart. CORTEX triangle footer. Neon blue translucent tiles, dark futuristic iOS aesthetic.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "atlas_ops",
            label: "ATLAS Ops OS",
            shortLabel: "ATLAS",
            aspectRatio: .landscape,
            style: .atlasOps,
            prompt: """
            ATLAS Operational Intelligence OS marketing — gold compass A logo, four phone mockups for \
            operations dashboard, dispatch timeline, field asset wireframe sensors, executive analytics. \
            Cyan and gold on navy. Tagline ENVIRONMENTAL. OPERATIONAL. BUSINESS. ONE SYSTEM. TOTAL CLARITY.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "s0_cli",
            label: "SIGNAL ZERO CLI",
            shortLabel: "S0 CLI",
            aspectRatio: .landscape,
            style: .signalZeroBlue,
            prompt: """
            SIGNAL ZERO CLI Terminal Command Layer marketing — laptop Operator Mode terminal with command \
            stack, autocomplete, system metrics, mobile session overview, four execution lanes. Crest logo, \
            DIRECT ACCESS. FULL CONTROL. ZERO ABSTRACTION. Dark cyberpunk operator aesthetic, ice blue.
            """,
            negativePrompt: sharedNegative
        ),
        CortexMarketingCampaign(
            id: "s0_execution",
            label: "S0 Execution Layer",
            shortLabel: "S0 Exec",
            aspectRatio: .portrait,
            style: .signalZeroBlue,
            prompt: """
            SIGNAL ZERO Execution Layer marketing — four iPhones arc: command console radar, execution tasks \
            progress list, secure voice waveform, systems wireframe overview. Electric blue on black tactical HUD. \
            DOWNLOAD CTA, THIS ISN'T AN APP. IT'S YOUR ADVANTAGE.
            """,
            negativePrompt: sharedNegative
        ),
    ]

    static func campaign(id: String) -> CortexMarketingCampaign? {
        campaigns.first { $0.id == id }
    }

    static func enrichedPrompt(base: String, style: ImageStylePreset) -> String {
        let styleLaw = style.marketingDirective
        return "\(base). \(brandLaw) \(styleLaw)"
    }
}
