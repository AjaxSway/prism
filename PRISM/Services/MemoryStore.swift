import Foundation

// MARK: - PRISM Memory Store
// Persists conversation history across sessions via UserDefaults.
// keyed separately from Signal Zero so each app owns its own memory lane.
// @MainActor ensures all history mutations are serialized on the main actor —
// BrainConnector calls append() from inside Task{} blocks which inherit the
// caller's actor context, so this prevents concurrent array mutation.

@MainActor
final class MemoryStore {
    static let shared = MemoryStore()
    private let maxMessages = 40
    private let fileURL: URL
    private init() {
        fileURL = PrismBrainMount.memoryFileURL()
    }

    struct Message: Codable {
        let role: String
        let content: String
        let timestamp: Date
    }

    private(set) var history: [Message] = []

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let messages = try? JSONDecoder().decode([Message].self, from: data) else { return }
        history = messages
    }

    func append(role: String, content: String) {
        history.append(Message(role: role, content: content, timestamp: Date()))
        if history.count > maxMessages { history = Array(history.suffix(maxMessages)) }
        save()
    }

    func contextMessages() -> [(role: String, content: String)] {
        history.map { (role: $0.role, content: $0.content) }
    }

    func clear() {
        history = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
