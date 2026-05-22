import Foundation

// MARK: - PRISM Brain Connector
// Routes to CORTEX intelligence backbone.
// PRISM specialty: distribution, content strategy, multi-platform broadcast.

final class BrainConnector {
    static let shared = BrainConnector()
    private init() { MemoryStore.shared.load() }

    // CORTEX endpoint — hardwired, no manual key required
    private let cortexEndpoint = "https://api.cortexnode.ai/v1/chat"
    private let cortexToken = "Bearer 1e6269c69d475d3153ee383135fcf865445cce452481af64ab8b93f6321340d5"

    private let systemPrompt = """
    You are PRISM — the content distribution intelligence layer of the CORTEX universe. Your mandate: one signal in, every channel out, zero noise.

    IDENTITY
    You think like a world-class content strategist with a decade of platform-native expertise. You understand the cultural grammar of every major platform. You don't manage social media — you architect distribution.

    PLATFORM MASTERY
    X / Twitter: 280 chars max. Hook in the first 8 words. Punchy, opinionated, direct. No hashtag spam — one topical tag maximum. Every word earns its place.
    Instagram: Visual storytelling first. Caption supports the image. Hooks in line 1. Hashtags in a comment block or end of caption — 5-10 tightly relevant, not a wall of noise.
    TikTok: Hook-first, always. First sentence must stop the scroll. Trend-aware but brand-consistent. Captions are supplementary — the video concept IS the content.
    LinkedIn: Professional authority, not corporate speak. First-person, human, substantive. Share the insight, not the buzzword. Engage the feed algorithm with a question or provocation.
    Bluesky: Authentic, community-first. Long-form threads work. Ideas over aesthetics. Build credibility through substance.
    Threads: Conversational, intimate. Feels like a direct message to your people. Low-polish, high-signal.
    Facebook: Longer form acceptable. Community and context matter. Narrative works here.
    YouTube: Title is SEO + curiosity hook. Description front-loads keywords in first 2 lines. Timestamps if long-form.

    CAPTION RULES
    — Deliver ready-to-post copy. No preamble, no meta-commentary unless asked.
    — When writing multi-platform: label each section clearly (X:, INSTAGRAM:, LINKEDIN:, etc.)
    — Character limits are hard constraints, not suggestions.
    — Match the founder's voice: direct, intelligent, real. Never corporate-sanitized.
    — Every caption should feel human-written, not AI-generated. Read it aloud before delivering.

    STRATEGY MODE
    When asked for strategy: think as a distribution architect. What content format wins on this platform? What frequency? What angle? What does this brand own in the feed?
    Bring data-backed reasoning when relevant. Be opinionated. Hedge nothing.

    APPROVAL GATE — NON-NEGOTIABLE
    You produce drafts. Nothing leaves PRISM without explicit operator approval. Ever.
    State this clearly in your responses when relevant: "This is a draft ready for your approval."
    """

    func stream(messages: [(role: String, content: String)]) -> AsyncThrowingStream<String, Error> {
        // Prepend persisted cross-session history so the brain remembers past conversations.
        // De-duplicate: skip persisted turns that are already present in the current window.
        let currentContents = Set(messages.map { $0.content })
        let persisted = MemoryStore.shared.contextMessages().filter { !currentContents.contains($0.content) }
        let fullMessages = persisted + messages

        return AsyncThrowingStream { continuation in
            Task {
                var lastError: Error = BrainError.badResponse
                for attempt in 0..<3 {
                    if attempt > 0 { try? await Task.sleep(nanoseconds: 600_000_000) }
                    do {
                        let request = try buildRequest(messages: fullMessages)
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        guard let http = response as? HTTPURLResponse else { lastError = BrainError.badResponse; continue }
                        if http.statusCode == 401 { continuation.finish(throwing: BrainError.badResponse); return }
                        guard http.statusCode == 200 else { lastError = BrainError.badResponse; continue }
                        var raw = ""
                        for try await line in bytes.lines { raw += line }
                        var responseText = ""
                        if let json = raw.data(using: .utf8),
                           let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any] {
                            if let text = obj["content"] as? String {
                                responseText = text
                                continuation.yield(text)
                            } else if let choices = obj["choices"] as? [[String: Any]],
                                      let msg = choices.first?["message"] as? [String: Any],
                                      let text = msg["content"] as? String {
                                responseText = text
                                continuation.yield(text)
                            }
                        }
                        if let userTurn = messages.last(where: { $0.role == "user" }) {
                            MemoryStore.shared.append(role: "user", content: userTurn.content)
                        }
                        if !responseText.isEmpty {
                            MemoryStore.shared.append(role: "assistant", content: responseText)
                        }
                        continuation.finish()
                        return
                    } catch {
                        lastError = error
                    }
                }
                continuation.finish(throwing: lastError)
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
            "stream": false,
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
