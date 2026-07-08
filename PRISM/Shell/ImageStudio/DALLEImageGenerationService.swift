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

    // MARK: - Helpers

    private func stylePrompt(base: String, style: ImageStylePreset, negative: String) -> String {
        let styleTag: String
        switch style {
        case .cortexTech:      styleTag = "cinematic dark tech HUD, neon glows, black background, sharp render"
        case .nodeBlueprint:   styleTag = "glowing circuit blueprint, deep blue, node network, geometric precision"
        case .executiveDark:   styleTag = "premium dark cinematic, executive aesthetic, clean contrast, moody lighting"
        case .minimalGlass:    styleTag = "minimal glass morphism, translucent surfaces, ultra clean, dark mode"
        }
        var prompt = "\(base). \(styleTag)."
        if !negative.isEmpty {
            prompt += " Avoid: \(negative)."
        }
        return prompt
    }
}

// MARK: - Aspect Ratio Dimensions

extension ImageAspectRatio {
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .square:    return (1024, 1024)
        case .landscape: return (1792, 1024)
        case .portrait:  return (1024, 1792)
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
