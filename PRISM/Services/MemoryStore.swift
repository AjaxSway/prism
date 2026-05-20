import Foundation

// MARK: - PRISM Memory Store
// Persists conversation history across sessions via UserDefaults.
// keyed separately from Signal Zero so each app owns its own memory lane.

final class MemoryStore {
    static let shared = MemoryStore(appKey: "prism.memory")
    private let key: String
    private let maxMessages = 40
    private init(appKey: String) { self.key = appKey }

    struct Message: Codable {
        let role: String
        let content: String
        let timestamp: Date
    }

    private(set) var history: [Message] = []

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
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

    func clear() { history = []; UserDefaults.standard.removeObject(forKey: key) }

    private func save() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
