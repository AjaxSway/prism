import SwiftUI
import CortexEcosystemBrain

@main
struct PRISMApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Task { @MainActor in
            ShellIntroMusic.shared.ensurePlaying()
        }
        _ = PrismBrainMount.ensure()
    }

    var body: some Scene {
        WindowGroup {
            ShellUniverseIntroGate(shellConfig: .prism, introConfig: .prism) {
                PremiumShellRouter(config: .prism)
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ShellIntroMusic.shared.ensurePlaying()
            }
        }
    }
}
