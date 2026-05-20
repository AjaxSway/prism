import Foundation

// MARK: - Blotato REST Service
// Calls Blotato's API to publish approved posts to connected social accounts.
// Account IDs are fixed to the CORTEXNODE brand accounts.

@MainActor
final class BlotatoService {
    static let shared = BlotatoService()
    private init() {}

    // Hardcoded Blotato key — CORTEXNODE workspace (verified 2026-05-17)
    private let defaultBlotatoKey = ""

    private var apiKey: String {
        let stored = UserDefaults.standard.string(forKey: "blotato_api_key") ?? ""
        return stored.isEmpty ? defaultBlotatoKey : stored
    }

    // CORTEXNODE brand account IDs (live from Blotato workspace — verified 2026-05-17)
    private let accountIds: [String: Int] = [
        "twitter":   15515,  // @CortexNodeAI
        "instagram": 38870,  // @cortexnode.ai
        "tiktok":    41309,  // @cortexnode
        "linkedin":  16810,  // George Bayze / CORTEXNODE page
        "bluesky":   31454,  // cortexnode.bsky.social
        "threads":   5625,   // @cortexnode.ai
        "facebook":  25358,  // George Bayze → CORTEXNODE.ai page
        "youtube":   32333,  // George Bayze (CORTEXNODE)
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
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw BlotatoError.apiError(msg)
        }
    }

    enum BlotatoError: LocalizedError {
        case invalidURL, networkError, apiError(String)
        var errorDescription: String? {
            switch self {
            case .invalidURL:       return "Invalid URL"
            case .networkError:     return "Network error"
            case .apiError(let m):  return m
            }
        }
    }
}
