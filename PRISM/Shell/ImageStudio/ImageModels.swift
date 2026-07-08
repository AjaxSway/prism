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

    var id: String { rawValue }
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

    enum Status: String {
        case queued, generating, completed, failed, blocked
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
