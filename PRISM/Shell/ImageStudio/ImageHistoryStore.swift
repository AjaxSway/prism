import Foundation

@MainActor
@Observable
final class ImageHistoryStore {
    private(set) var jobs: [ImageJob] = []
    private(set) var results: [ImageResult] = []
    var selectedResult: ImageResult?

    func stageOfflineJob(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset
    ) {
        let job = ImageJob(
            id: UUID(),
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            createdAt: Date(),
            status: .blocked
        )
        jobs.insert(job, at: 0)
    }

    func reset() {
        jobs.removeAll()
        results.removeAll()
        selectedResult = nil
    }
}
