import Foundation

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
        case queued, blocked, completed
    }
}

struct ImageResult: Identifiable, Equatable {
    let id: UUID
    let jobID: UUID
    let prompt: String
    let placeholderSymbol: String
    let createdAt: Date
    let modelPlaceholder: String
}

enum ImageGenerationEndpoint {
    static let futurePath = "/api/image/generate"
}
