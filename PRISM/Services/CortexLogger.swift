import Foundation

// MARK: - Log Category

enum LogCategory: String, CaseIterable {
    case system  = "SYSTEM"
    case api     = "API"
    case network = "NETWORK"
    case voice   = "VOICE"
    case security = "SECURITY"
    case finance = "FINANCE"
    case tesla   = "TESLA"
    case command = "COMMAND"
    case intelligence = "INTELLIGENCE"
}

// MARK: - Log Entry

struct LogEntry: Identifiable {
    let id = UUID()
    let category: LogCategory
    let message: String
    let timestamp: Date
    let level: LogLevel

    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
}

// MARK: - Cortex Logger

/// Ring buffer logger for diagnostics console. Stores last 500 entries.
@MainActor
final class CortexLogger: ObservableObject {
    static let shared = CortexLogger()

    @Published private(set) var entries: [LogEntry] = []
    private let maxEntries = 500

    private init() {}

    func log(_ message: String, category: LogCategory, level: LogEntry.LogLevel = .info) {
        let entry = LogEntry(category: category, message: message, timestamp: Date(), level: level)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func info(_ message: String, category: LogCategory) {
        log(message, category: category, level: .info)
    }

    func warn(_ message: String, category: LogCategory) {
        log(message, category: category, level: .warning)
    }

    func error(_ message: String, category: LogCategory) {
        log(message, category: category, level: .error)
    }

    /// Thread-safe logging from any context. Dispatches to MainActor internally.
    nonisolated static func send(_ message: String, category: LogCategory, level: LogEntry.LogLevel = .info) {
        Task { @MainActor in
            shared.log(message, category: category, level: level)
        }
    }

    func clear() {
        entries.removeAll()
    }

    func entries(for category: LogCategory) -> [LogEntry] {
        entries.filter { $0.category == category }
    }

    func recentEntries(count: Int = 50) -> [LogEntry] {
        Array(entries.suffix(count))
    }
}
