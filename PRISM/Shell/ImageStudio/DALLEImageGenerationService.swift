import Foundation

// MARK: - DALL-E 3 Image Generation Service
// Routes through api.cortexnode.ai/generate-image using the device session token.
// Replaces MockImageGenerationService — this is the real engine.

struct DALLEImageGenerationService: ImageGenerationService {
    private let authSession = AuthSessionStore.shared

    func generate(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset
    ) async -> ImageJob {
        let jobID = UUID()
        let job = ImageJob(
            id: jobID,
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            createdAt: Date(),
            status: .generating
        )

        return job
    }

    // Returns the image URL string on success, throws on failure.
    func generateURL(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset,
        quality: ImageQuality
    ) async throws -> URL {
        let token = try await authSession.validSessionToken()

        guard let url = URL(string: ImageGenerationEndpoint.base + ImageGenerationEndpoint.path) else {
            throw ImageGenError.invalidEndpoint
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 90
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (w, h) = aspectRatio.dimensions
        let enhancedPrompt = stylePrompt(base: prompt, style: style, negative: negativePrompt)

        let body: [String: Any] = [
            "prompt":      enhancedPrompt,
            "width":       w,
            "height":      h,
            "num_outputs": 1,
            "quality":     quality.apiValue
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw ImageGenError.badResponse }
        guard http.statusCode == 200 else { throw ImageGenError.serverError(http.statusCode) }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImageGenError.parseError
        }

        // Response shape: { data: { images: [ { url: "..." } ] } }  OR  { images: [ "url" ] }
        if let dataObj = json["data"] as? [String: Any],
           let images = dataObj["images"] as? [[String: Any]],
           let urlStr = images.first?["url"] as? String,
           let imageURL = URL(string: urlStr) {
            return imageURL
        }

        // Flat array fallback
        if let images = json["images"] as? [String],
           let urlStr = images.first,
           let imageURL = URL(string: urlStr) {
            return imageURL
        }

        // Single URL field fallback
        if let urlStr = json["url"] as? String,
           let imageURL = URL(string: urlStr) {
            return imageURL
        }

        throw ImageGenError.parseError
    }

    // MARK: - Async job + poll path (real generation path)
    //
    // High/Ultra-quality generation on the backend can legitimately take
    // 2-3+ minutes (the server allows up to 240s just for the OpenAI call).
    // Holding one synchronous HTTP request open that long on a mobile
    // client is unreliable — cellular handoffs, backgrounding, and the
    // client's own timeout will fire long before the image is ready, even
    // though the server is still correctly working and will succeed.
    // Confirmed on 2026-07-21: a real request completed successfully and
    // saved a file server-side ~3 minutes after being sent, well after the
    // client had already given up and shown a false "Offline" error.
    //
    // The fix is architectural, not a bigger timeout number: create a job,
    // then poll it with short-lived requests until it resolves. Each poll
    // is quick and cheap regardless of how long generation itself takes.
    func generateViaAsyncJob(
        prompt: String,
        negativePrompt: String,
        aspectRatio: ImageAspectRatio,
        style: ImageStylePreset,
        quality: ImageQuality,
        jobLog: (String) -> Void = { _ in },
        onProgress: (String) -> Void = { _ in }
    ) async throws -> URL {
        let token = try await authSession.validSessionToken()
        jobLog("auth=accepted")

        guard let startURL = URL(string: ImageGenerationEndpoint.base + "/generate-image-async") else {
            throw ImageGenError.invalidEndpoint
        }
        let (w, h) = aspectRatio.dimensions
        let enhancedPrompt = stylePrompt(base: prompt, style: style, negative: negativePrompt)

        var startReq = URLRequest(url: startURL)
        startReq.httpMethod = "POST"
        startReq.timeoutInterval = 30
        startReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        startReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        startReq.httpBody = try JSONSerialization.data(withJSONObject: [
            "prompt": enhancedPrompt,
            "quality": quality.apiValue,
            "width": w,
            "height": h,
        ])

        let (startData, startResponse) = try await URLSession.shared.data(for: startReq)
        guard let startHTTP = startResponse as? HTTPURLResponse else { throw ImageGenError.badResponse }
        guard startHTTP.statusCode == 200 else { throw ImageGenError.serverError(startHTTP.statusCode) }
        guard let startJSON = try? JSONSerialization.jsonObject(with: startData) as? [String: Any],
              let jobId = startJSON["job_id"] as? String else {
            throw ImageGenError.parseError
        }
        jobLog("job_id=\(jobId) dispatched")

        // Server allows ~240s for the provider call itself; give real margin
        // on top for job-store overhead and poll cadence, without holding a
        // single connection open the whole time.
        let deadline = Date().addingTimeInterval(300)
        let pollURL = URL(string: ImageGenerationEndpoint.base + "/generate-image-async/\(jobId)")!

        while Date() < deadline {
            try await Task.sleep(for: .seconds(3))

            var pollReq = URLRequest(url: pollURL)
            pollReq.timeoutInterval = 15
            pollReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            guard let (pollData, pollResponse) = try? await URLSession.shared.data(for: pollReq),
                  let pollHTTP = pollResponse as? HTTPURLResponse,
                  pollHTTP.statusCode == 200,
                  let pollJSON = try? JSONSerialization.jsonObject(with: pollData) as? [String: Any] else {
                continue // transient poll miss — the job itself is still valid, keep polling until deadline
            }

            let status = pollJSON["status"] as? String ?? ""
            if let progress = pollJSON["progress_message"] as? String { onProgress(progress) }

            switch status {
            case "succeeded":
                guard let urlStr = pollJSON["final_url"] as? String, let finalURL = URL(string: urlStr) else {
                    throw ImageGenError.parseError
                }
                jobLog("job_id=\(jobId) succeeded")
                return finalURL
            case "failed":
                let msg = (pollJSON["error"] as? String) ?? "Generation failed"
                jobLog("job_id=\(jobId) failed: \(msg)")
                throw ImageJobError.failed(msg)
            default:
                continue // queued / running
            }
        }

        jobLog("job_id=\(jobId) timed out polling")
        throw ImageJobError.timedOutPolling
    }

    // MARK: - Helpers

    private func stylePrompt(base: String, style: ImageStylePreset, negative: String) -> String {
        var prompt = CortexMarketingImageCanon.enrichedPrompt(base: base, style: style)
        let neg = negative.isEmpty ? CortexMarketingImageCanon.sharedNegative : negative
        prompt += " Avoid: \(neg)."
        return prompt
    }
}

enum ImageJobError: LocalizedError {
    case failed(String)
    case timedOutPolling

    var errorDescription: String? {
        switch self {
        case .failed(let reason): return reason
        case .timedOutPolling:    return "Generation is taking longer than expected."
        }
    }
}

// MARK: - Aspect Ratio Dimensions

extension ImageAspectRatio {
    var dimensions: (width: Int, height: Int) {
        switch self {
        // gpt-image-1 supported sizes (DALL-E 3 retired on this account)
        case .square:    return (1024, 1024)
        case .landscape: return (1536, 1024)
        case .portrait:  return (1024, 1536)
        }
    }
}

// MARK: - Quality API value

extension ImageQuality {
    var apiValue: String {
        switch self {
        case .standard: return "standard"
        case .high:     return "hd"
        case .ultra:    return "ultra"
        }
    }
}

// MARK: - Errors

enum ImageGenError: LocalizedError {
    case invalidEndpoint
    case badResponse
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:     return "Image endpoint is misconfigured."
        case .badResponse:         return "No response from image server."
        case .serverError(let c):  return "Image server returned \(c)."
        case .parseError:          return "Could not parse image URL from response."
        }
    }
}
