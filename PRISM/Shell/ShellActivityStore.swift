import Foundation

struct ShellActivityEvent: Identifiable, Equatable {
    enum Kind: String {
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
    private(set) var events: [ShellActivityEvent] = []

    func append(title: String, detail: String, kind: ShellActivityEvent.Kind) {
        events.insert(
            ShellActivityEvent(id: UUID(), timestamp: Date(), title: title, detail: detail, kind: kind),
            at: 0
        )
    }

    func reset() {
        events.removeAll()
    }
}
