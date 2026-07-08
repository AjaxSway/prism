import SwiftUI

extension CortexChatTheme {
    static var app: CortexChatTheme {
        CortexChatThemes.theme(
            surfaceKey: "prism",
            appTitle: "PRISM",
            tagline: "Communication · Publishing",
            accent: Color(red: 0.72, green: 0.25, blue: 1),
            accentSoft: Color(red: 0.93, green: 0.28, blue: 0.6),
            background: Color(red: 0.008, green: 0.012, blue: 0.027),
            panel: Color(red: 0.06, green: 0.02, blue: 0.1).opacity(0.94),
            heroIcon: "dot.radiowaves.left.and.right",
            systemPrompt: CortexChatThemes.prismPrompt,
            greeting: "PRISM online. Same CORTEX brain — publishing surface. What are we creating?",
            speak: { VoiceService.speak($0) }
        )
    }
}
