import Foundation

@MainActor
@Observable
final class PRISMState {
    static let shared = PRISMState()
    var messages: [BrainMessage] = []
    var lastPrompt: String = ""
    var sessionStart = Date()
    // CORTEX endpoint is hardwired — brain is always connected
    var hasAPIKey: Bool { true }
    private init() {
        messages.append(BrainMessage(role: .system, content: "PRISM online. Intelligence relay armed. Ready to reveal."))
    }
    func addMessage(role: BrainMessage.Role, content: String) {
        messages.append(BrainMessage(role: role, content: content))
    }

    struct BrainMessage: Identifiable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp = Date()
        enum Role { case user, assistant, system }
        var timeString: String {
            let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: timestamp)
        }
    }
}
