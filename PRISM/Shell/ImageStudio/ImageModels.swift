import Foundation

enum ImageQuality: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case high = "High"
    case ultra = "Ultra"

    var id: String { rawValue }
}

enum ImageAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case landscape = "16:9"
    case portrait = "9:16"

    var id: String { rawValue }
}

enum ImageStylePreset: String, CaseIterable, Identifiable {
    case cortexTech = "CORTEX Tech"
    case nodeBlueprint = "Node Blueprint"
    case executiveDark = "Executive Dark"
    case minimalGlass = "Minimal Glass"
    // CORTEX MARKETING · God Mode (Sir reference boards)
    case cortexBrandSheet = "CORTEX Brand"
    case signalZeroBlue = "Signal Zero"
    case jerichoRed = "Jericho Red"
    case godModeHUD = "God Mode HUD"
    case babiesChibi = "Babies Chibi"
    case sovereignGold = "Sovereign"
    case aurionGoldRed = "Aurion Gold"
    case pricingHero = "Pricing Hero"
    case vehicleCommand = "Vehicle UI"
    case atlasOps = "Atlas Ops"

    var id: String { rawValue }

    /// Style directive appended by DALL-E enrichment / marketing canon.
    var marketingDirective: String {
        switch self {
        case .cortexTech:
            return "Cinematic dark tech HUD, neon glows, black background, sharp render."
        case .nodeBlueprint:
            return "Glowing circuit blueprint, deep blue, node network, geometric precision."
        case .executiveDark:
            return "Premium dark cinematic, executive aesthetic, clean contrast, moody lighting."
        case .minimalGlass:
            return "Minimal glass morphism, translucent surfaces, ultra clean, dark mode."
        case .cortexBrandSheet:
            return "Metallic beveled CORTEX wordmark, cyan bloom, quick-sheet HUD, brand splash."
        case .signalZeroBlue:
            return "Ice-blue neon on void black, SIGNAL ZERO operator aesthetic, clean tactical UI."
        case .jerichoRed:
            return "Crimson tactical war-room, industrial metal type, threat-red particles."
        case .godModeHUD:
            return "Circular vault HUD, crown biometric lock, corner status widgets, God Mode."
        case .babiesChibi:
            return "Premium chibi CORTEX Baby characters, collectible cards, glowing cores, cute + industrial."
        case .sovereignGold:
            return "Cyber-imperial gold and obsidian, crown, sovereign command poster."
        case .aurionGoldRed:
            return "Polished gold armor, red reactor eyes, championship war-room holograms."
        case .pricingHero:
            return "SaaS pricing landing density, neon plan cards, starfield marketing layout."
        case .vehicleCommand:
            return "CORTEX vehicle command iOS mockups, translucent tiles, neon blue Tesla aesthetic."
        case .atlasOps:
            return "ATLAS ops OS, gold and cyan enterprise dashboards, field intelligence phones."
        }
    }
}

struct ImagePreset: Identifiable, Equatable {
    let id: String
    let label: String
    let style: ImageStylePreset
}

struct ImageJob: Identifiable, Equatable {
    let id: UUID
    let prompt: String
    let negativePrompt: String
    let aspectRatio: ImageAspectRatio
    let style: ImageStylePreset
    let createdAt: Date
    var status: Status
    /// Sanitized, user-facing reason — set only on .failed or .blocked. Never contains raw URLs, tokens, or provider internals.
    var errorMessage: String? = nil
    /// Latest server-reported progress ("generating base image", "upscaling", etc.) — cosmetic only.
    var progressDetail: String? = nil

    enum Status: String {
        case queued, generating, completed, failed, blocked

        /// Truthful, user-facing label — no state may imply success it hasn't earned.
        var displayLabel: String {
            switch self {
            case .queued:     return "Preparing"
            case .generating: return "Generating"
            case .completed:  return "Completed"
            case .failed:     return "Failed"
            case .blocked:    return "Offline"
            }
        }
    }
}

struct ImageResult: Identifiable, Equatable {
    let id: UUID
    let jobID: UUID
    let prompt: String
    let imageURL: URL?
    let createdAt: Date
    let model: String
}

enum ImageGenerationEndpoint {
    static let path = "/generate-image"
    static let base = "https://api.cortexnode.ai"
}
