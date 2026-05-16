import Foundation

// MARK: - Brain Connector
// Shared intelligence layer for all five apps.
// Connects to the same CORTEX AI backbone via streaming API.

final class BrainConnector {
    static let shared = BrainConnector()
    private init() {}

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "brain_api_key") ?? ""
    }

    func stream(messages: [(role: String, content: String)]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard !apiKey.isEmpty else {
                    continuation.finish(throwing: BrainError.noAPIKey)
                    return
                }
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
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "stream": true,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }
}

enum BrainError: Error {
    case noAPIKey
    case badResponse
}
