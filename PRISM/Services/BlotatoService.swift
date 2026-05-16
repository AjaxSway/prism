import Foundation

// MARK: - Blotato REST Service
// Calls Blotato's API to publish approved posts to connected social accounts.
// Account IDs are fixed to the CORTEXNODE brand accounts.

@MainActor
final class BlotatoService {
    static let shared = BlotatoService()
    private init() {}

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "blotato_api_key") ?? ""
    }

    // CORTEXNODE brand account IDs (from Blotato workspace)
    private let accountIds: [String: Int] = [
        "twitter":   15515,  // @CortexNodeAI
        "instagram": 38870,  // @cortexnode.ai
        "tiktok":    41309,  // @cortexnode
        "linkedin":  16810,  // George Bayze / CORTEXNODE
        "bluesky":   31454,  // cortexnode.bsky.social
        "threads":   5625,   // @cortexnode.ai
    ]

    struct PostResult {
        let platform: String
        let success: Bool
        let error: String?
    }

    func post(content: String, platforms: [Platform]) async -> [PostResult] {
        guard !apiKey.isEmpty else {
            return platforms.map { PostResult(platform: blotatoKey($0), success: false, error: "No Blotato API key") }
        }

        var results: [PostResult] = []
        for platform in platforms {
            let key = blotatoKey(platform)
            guard let accountId = accountIds[key] else {
                results.append(PostResult(platform: key, success: false, error: "No account mapped"))
                continue
            }
            do {
                try await createPost(accountId: accountId, platform: key, text: content)
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
