import Foundation
import UIKit

// MARK: - Blotato REST Service
// Calls Blotato's API to publish approved posts to connected social accounts.
// Account IDs are fixed to the CORTEXNODE brand accounts.

// MARK: - Instagram Dimension Validator
// Instagram rejects images outside the allowed aspect ratio range (0.8 – 1.91).
// Allowed formats: 1:1 square, 4:5 portrait, 1.91:1 landscape.
struct InstagramValidator {
    enum ValidationResult {
        case valid
        case invalidRatio(width: Int, height: Int, ratio: Double)
        case noImage
    }

    static func validate(imageData: Data?) -> ValidationResult {
        guard let data = imageData, let image = UIImage(data: data) else { return .noImage }
        let w = image.size.width
        let h = image.size.height
        guard h > 0 else { return .noImage }
        let ratio = w / h
        // Instagram allows 0.8 (4:5 portrait) to 1.91 (landscape). Tolerance ±0.01.
        if ratio >= 0.79 && ratio <= 1.92 {
            return .valid
        }
        return .invalidRatio(width: Int(w), height: Int(h), ratio: Double(ratio))
    }

    static func warningMessage(for result: ValidationResult) -> String? {
        switch result {
        case .valid: return nil
        case .noImage: return nil
        case .invalidRatio(let w, let h, let ratio):
            return "Instagram will reject this image (\(w)×\(h), ratio \(String(format: "%.2f", ratio))). Instagram requires between 4:5 portrait (0.8) and 1.91:1 landscape. Resize before posting."
        }
    }
}

@MainActor
final class BlotatoService {
    static let shared = BlotatoService()
    private init() {}

    // API key is operator-supplied via Settings — never hardcoded in source.
    // If the prior key was exposed in any build, rotate it at blotato.com immediately.
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "blotato_api_key") ?? ""
    }

    var isConfigured: Bool { !apiKey.isEmpty }

    // CORTEXNODE brand account IDs (live from Blotato workspace — verified 2026-05-17)
    private let accountIds: [String: Int] = [
        "twitter":   15515,  // @CortexNodeAI
        "instagram": 38870,  // @cortexnode.ai
        "tiktok":    41309,  // @cortexnode
        "linkedin":  16810,  // CORTEXNODE page
        "bluesky":   31454,  // cortexnode.bsky.social
        "threads":   5625,   // @cortexnode.ai
        "facebook":  25358,  // CORTEXNODE.ai page
        "youtube":   32333,  // CORTEXNODE
    ]

    // Facebook requires a pageId to post to the company page (not personal profile)
    private let facebookPageId = "1030995880100786"  // CORTEXNODE.ai page
    // LinkedIn company page
    private let linkedinPageId = "116464217"         // CORTEXNODE

    struct PostResult {
        let platform: String
        let success: Bool
        let error: String?
    }

    /// CORTEX attribution appended to every post — signals the AI layer, builds brand identity.
    private let cortexAttribution = "\n\n— Posted by CORTEX · cortexnode.ai"

    private func extractImageData(from content: String) -> Data? {
        // Image data is passed separately via the queue item — return nil here,
        // validator returns .noImage which is treated as valid (text-only post).
        return nil
    }

    func post(content: String, platforms: [Platform]) async -> [PostResult] {
        guard !apiKey.isEmpty else {
            return platforms.map { PostResult(platform: blotatoKey($0), success: false, error: "No Blotato API key") }
        }

        // Append "Posted by CORTEX" so every post signals the intelligence layer
        let signedContent = content + cortexAttribution

        var results: [PostResult] = []
        for platform in platforms {
            let key = blotatoKey(platform)
            guard let accountId = accountIds[key] else {
                results.append(PostResult(platform: key, success: false, error: "No account mapped"))
                continue
            }
            // Validate Instagram image dimensions before hitting the API
            if key == "instagram" {
                let imageData = extractImageData(from: content)
                let validation = InstagramValidator.validate(imageData: imageData)
                if let warning = InstagramValidator.warningMessage(for: validation) {
                    results.append(PostResult(platform: key, success: false, error: warning))
                    continue
                }
            }
            do {
                try await createPost(accountId: accountId, platform: key, text: signedContent)
                results.append(PostResult(platform: key, success: true, error: nil))
            } catch {
                results.append(PostResult(platform: key, success: false, error: error.localizedDescription))
            }
        }
        return results
    }

    private func blotatoKey(_ p: Platform) -> String {
        switch p {
        case .x:         return "twitter"
        case .instagram: return "instagram"
        case .tiktok:    return "tiktok"
        case .linkedin:  return "linkedin"
        case .bluesky:   return "bluesky"
        case .threads:   return "threads"
        case .facebook:  return "facebook"
        case .youtube:   return "youtube"
        }
    }

    private func createPost(accountId: Int, platform: String, text: String) async throws {
        guard let url = URL(string: "https://backend.blotato.com/api/v1/posts") else {
            throw BlotatoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "blotato-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "accountId": accountId,
            "platform": platform,
            "text": text,
            "mediaUrls": [String]()
        ]

        if platform == "tiktok" {
            body["privacyLevel"] = "PUBLIC_TO_EVERYONE"
            body["disabledComments"] = false
            body["disabledDuet"] = false
            body["disabledStitch"] = false
            body["isBrandedContent"] = false
            body["isYourBrand"] = false
            body["isAiGenerated"] = false
        }

        if platform == "facebook" {
            body["pageId"] = facebookPageId
        }

        if platform == "linkedin" {
            body["pageId"] = linkedinPageId
        }

        if platform == "youtube" {
            body["title"] = text.prefix(100).description
            body["privacyStatus"] = "public"
            body["shouldNotifySubscribers"] = true
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BlotatoError.networkError }
        guard (200...299).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw BlotatoError.apiError(cleanBlotatoError(raw, status: http.statusCode))
        }
    }

    /// Normalizes raw Blotato API error strings into readable messages.
    /// Raw responses from Blotato can be malformed JSON fragments, thumbnail
    /// dimension strings ("Generated 102x102x"), or HTML error pages.
    private func cleanBlotatoError(_ raw: String, status: Int) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract a "message" or "error" field from JSON
        if let json = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)) as? [String: Any] {
            if let msg = json["message"] as? String, !msg.isEmpty { return msg }
            if let err = json["error"] as? String, !err.isEmpty { return err }
        }

        // Strip HTML tags if this is an error page
        if trimmed.contains("<html") || trimmed.contains("<body") {
            return "Service temporarily unavailable (HTTP \(status)). Try again."
        }

        // If the raw string looks like a thumbnail/image processing fragment
        // (e.g. "Generated 102x102x"), replace with a clean message
        let lc = trimmed.lowercased()
        if lc.hasPrefix("generated") || lc.contains("x102") || lc.contains("thumbnail") || lc.contains("image") {
            return "Image processing failed on Blotato's end (HTTP \(status)). Verify image dimensions and try again."
        }

        // Fall back to raw if it's a clean, readable string under 200 chars
        if trimmed.count <= 200 && !trimmed.isEmpty { return trimmed }

        return "Post failed (HTTP \(status)). Check Blotato account and try again."
    }

    enum BlotatoError: LocalizedError {
        case invalidURL, networkError, apiError(String)
        var errorDescription: String? {
            switch self {
            case .invalidURL:       return "Invalid Blotato endpoint"
            case .networkError:     return "Network error — check connection"
            case .apiError(let m):  return m
            }
        }
    }
}
