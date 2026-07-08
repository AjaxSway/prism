import Foundation

struct ShellActivityEvent: Identifiable, Equatable, Codable {
    enum Kind: String, Codable {
        case info, navigation, command, warning, error
    }

    let id: UUID
    let timestamp: Date
    let title: String
    let detail: String
    let kind: Kind

    var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }
}

@MainActor
@Observable
final class ShellActivityStore {
    private let storageKey: String
    private(set) var events: [ShellActivityEvent] = []

    init(storageKey: String) {
        self.storageKey = storageKey
        load()
    }

    func append(title: String, detail: String, kind: ShellActivityEvent.Kind) {
        events.insert(
            ShellActivityEvent(id: UUID(), timestamp: Date(), title: title, detail: detail, kind: kind),
            at: 0
        )
        if events.count > 200 { events.removeLast(events.count - 200) }
        persist()
    }

    func reset() {
        events.removeAll()
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ShellActivityEvent].self, from: data) else { return }
        events = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
