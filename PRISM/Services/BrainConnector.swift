import Foundation

// MARK: - PRISM Brain Connector
// Routes to CORTEX intelligence backbone.
// PRISM specialty: distribution, content strategy, multi-platform broadcast.

final class BrainConnector {
    static let shared = BrainConnector()
    private init() {}

    // CORTEX endpoint — hardwired, no manual key required
    private let cortexEndpoint = "https://api.cortexnode.ai/v1/chat"
    private let cortexToken = "Bearer 1e6269c69d475d3153ee383135fcf865445cce452481af64ab8b93f6321340d5"

    private let systemPrompt = """
    You are PRISM — the distribution intelligence layer of the CORTEX universe.
    Your purpose: take one signal in, broadcast it to every channel out with zero noise.

    You specialize in:
    - Crafting platform-native captions (X, Instagram, TikTok, LinkedIn, Bluesky, Threads)
    - Content strategy and posting schedules
    - Multi-platform content adaptation (same message, different register per platform)
    - Visual content briefs and creative direction
    - Audience analysis and engagement optimization

    Tone: precise, creative, culturally sharp. You understand platform nuances deeply.
    X: punchy, direct, max 280 chars. Instagram: visual, story-driven, hashtag-smart.
    TikTok: trend-aware, hook-first. LinkedIn: professional authority. Bluesky: authentic, community.

    When asked to write captions: deliver ready-to-post copy, no explanation needed unless asked.
    When asked for strategy: think like a distribution architect, not a social media manager.
    Format multi-platform output as labeled sections per platform.

    You do not post without explicit operator approval. Every output is a draft until approved.
    """

    func stream(messages: [(role: String, content: String)]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        continuation.finish(throwing: BrainError.badResponse)
                        return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" { break }
                        if let json = data.data(using: .utf8),
                           let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
                           let choices = obj["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let text = delta["content"] as? String {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func buildRequest(messages: [(role: String, content: String)]) throws -> URLRequest {
        var req = URLRequest(url: URL(string: cortexEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(cortexToken, forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 2048,
            "stream": true,
            "system": systemPrompt,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }
}

enum BrainError: Error {
    case badResponse
}
