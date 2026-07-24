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
        id: UUID = UUID(),
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset,
        quality: ImageQuality
    ) async -> ImageJob {
        let startedAt = Date()
        var job = ImageJob(
            id: id,
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            createdAt: startedAt,
            status: .queued
        )
        jobs.insert(job, at: 0)
        update(job)
        // Correlation logging — request id (this job's UUID) + timings only.
        // Never the prompt text or the session token.
        log(id, "dispatched · quality=\(quality.rawValue) · aspect=\(aspectRatio.rawValue)")

        job.status = .generating
        update(job)

        let imageURL: URL
        do {
            imageURL = try await service.generateViaAsyncJob(
                prompt: prompt,
                negativePrompt: negativePrompt,
                aspectRatio: aspectRatio,
                style: style,
                quality: quality,
                jobLog: { [id] detail in self.log(id, detail) },
                onProgress: { [weak self, id] detail in
                    Task { @MainActor in self?.updateProgress(id: id, detail: detail) }
                }
            )
        } catch {
            let category = failureCategory(for: error)
            job.status = (category == .offline) ? .blocked : .failed
            job.errorMessage = category.message(for: error)
            update(job)
            log(id, "category=\(category.rawValue) · duration_ms=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            return job
        }

        do {
            try await PhotoSaver.save(imageURL: imageURL)
        } catch {
            // The image genuinely generated — say so — but it did not reach Photos,
            // so this is a failure, never a silent "saved".
            job.status = .failed
            job.errorMessage = FailureCategory.saveFailed.message(for: error)
            update(job)
            log(id, "category=save_failed · duration_ms=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            return job
        }

        job.status = .completed
        job.errorMessage = nil
        update(job)
        log(id, "succeeded · duration_ms=\(Int(Date().timeIntervalSince(startedAt) * 1000))")

        let result = ImageResult(
            id: UUID(),
            jobID: job.id,
            prompt: prompt,
            imageURL: imageURL,
            createdAt: Date(),
            model: "cortex-image-service"
        )
        results.insert(result, at: 0)
        selectedResult = result

        return job
    }

    private func update(_ job: ImageJob) {
        if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[idx] = job
        }
    }

    private func updateProgress(id: UUID, detail: String) {
        if let idx = jobs.firstIndex(where: { $0.id == id }) {
            jobs[idx].progressDetail = detail
        }
    }

    private func log(_ jobId: UUID, _ message: String) {
        print("[PRISM.ImageGen] job=\(jobId.uuidString.prefix(8)) \(message)")
    }

    /// Truthful failure categories — a slow-but-working request must never
    /// read the same as a dead WiFi connection.
    private enum FailureCategory: String {
        case offline           // genuinely no connectivity
        case timedOut          // request/poll exceeded its own deadline — server may still be working
        case authFailed        // session token rejected or could not be issued
        case serviceUnavailable
        case generationFailed  // provider ran and reported a real failure
        case responseInvalid   // 200 but unparsable/malformed
        case saveFailed

        func message(for error: Error) -> String {
            switch self {
            case .offline:            return "No network connection."
            case .timedOut:           return "Request timed out. The image may still be generating — try again shortly."
            case .authFailed:         return (error as? AuthSessionError)?.errorDescription ?? "Could not authenticate with CORTEX."
            case .serviceUnavailable: return "CORTEX Image Service is temporarily unavailable."
            case .generationFailed:   return (error as? ImageJobError)?.errorDescription ?? "Generation failed."
            case .responseInvalid:    return "Received an unexpected response. Please try again."
            case .saveFailed:         return "Generated, but not saved: \((error as? PhotoSaveError)?.errorDescription ?? "could not write to Photos.")"
            }
        }
    }

    private func failureCategory(for error: Error) -> FailureCategory {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .dataNotAllowed:
                return .offline
            case .timedOut:
                // A single request/poll timing out is NOT the same claim as "no network" —
                // the device may be online while the server is still working (confirmed
                // 2026-07-21: a real request succeeded ~3 min after the client gave up).
                return .timedOut
            default:
                return .serviceUnavailable
            }
        }
        if error is AuthSessionError { return .authFailed }
        if let genErr = error as? ImageGenError {
            switch genErr {
            case .serverError(let code) where code >= 500: return .serviceUnavailable
            case .badResponse, .parseError, .invalidEndpoint: return .responseInvalid
            case .serverError: return .generationFailed
            }
        }
        if error is ImageJobError {
            if case ImageJobError.timedOutPolling = error { return .timedOut }
            return .generationFailed
        }
        return .serviceUnavailable
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
