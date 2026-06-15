import SwiftUI

enum ShellOrbState: String, CaseIterable, Identifiable {
    case idle, listening, thinking, speaking, executing, success, warning, error, offline

    var id: String { rawValue }

    var label: String {
        switch self {
        case .idle: return "Idle"
        case .listening: return "Listening"
        case .thinking: return "Thinking"
        case .speaking: return "Speaking"
        case .executing: return "Executing"
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .offline: return "Offline"
        }
    }
}
