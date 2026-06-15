import Foundation

protocol ImageGenerationService {
    func generate(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset
    ) async -> ImageJob
}

struct MockImageGenerationService: ImageGenerationService {
    func generate(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset
    ) async -> ImageJob {
        ImageJob(
            id: UUID(),
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            createdAt: Date(),
            status: .blocked
        )
    }
}
