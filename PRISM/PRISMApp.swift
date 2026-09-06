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
            .task {
                await CortexUniverseRuntime.bootstrap(
                    scheme: "prism",
                    bundleId: "com.cortexnode.prism"
                )
            }
            .onOpenURL { url in
                PrismUniverseHandoff.handle(url)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ShellIntroMusic.shared.ensurePlaying()
            }
        }
    }
}

enum PrismUniverseHandoff {
    static func handle(_ url: URL) {
        let client = CortexUniverseRuntime.client(
            scheme: "prism",
            bundleId: "com.cortexnode.prism"
        )
        switch client.evaluateIncomingURL(url) {
        case .ignore, .tokenlessOpen:
            break
        case .rejected(let reason):
            print("[CORTEX-UNIVERSE] handoff rejected: \(reason)")
        case .redeem(let code):
            Task {
                let outcome = await client.redeem(code: code)
                print("[CORTEX-UNIVERSE] redeem \(outcome)")
            }
        }
    }
}
