import Foundation

@MainActor
@Observable
final class ImageHistoryStore {
    private(set) var jobs: [ImageJob] = []
    private(set) var results: [ImageResult] = []
    var selectedResult: ImageResult?

    private let service = DALLEImageGenerationService()

    // MARK: - Real generation

    func generate(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset,
        quality: ImageQuality
    ) async -> ImageJob {
        var job = ImageJob(
            id: UUID(),
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            createdAt: Date(),
            status: .generating
        )
        jobs.insert(job, at: 0)

        do {
            let imageURL = try await service.generateURL(
                prompt: prompt,
                negativePrompt: negativePrompt,
                aspectRatio: aspectRatio,
                style: style,
                quality: quality
            )
            job.status = .completed
            if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[idx] = job
            }
            let result = ImageResult(
                id: UUID(),
                jobID: job.id,
                prompt: prompt,
                imageURL: imageURL,
                createdAt: Date(),
                model: "gpt-image-1"
            )
            results.insert(result, at: 0)
            selectedResult = result
        } catch {
            job.status = .failed
            if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[idx] = job
            }
        }

        return job
    }

    // MARK: - Offline staging (kept for fallback when brain is offline)

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
