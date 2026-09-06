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
        guard url.scheme?.lowercased() == "prism" else { return }
        guard (url.host ?? "").lowercased() == "universe" else { return }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let forbidden = ["firebase", "id_token", "access_token", "refresh_token", "bearer", "founder", "god_mode", "password", "api_key", "session"]
        for item in items {
            let name = item.name.lowercased()
            if name != "token", forbidden.contains(where: { name.contains($0) }) {
                print("[CORTEX-UNIVERSE] handoff rejected: forbidden field")
                return
            }
            if name == "token", (item.value ?? "").count > 128 {
                print("[CORTEX-UNIVERSE] handoff rejected: token too large")
                return
            }
        }
        let path = url.path.lowercased()
        let token = items.first(where: { $0.name == "token" })?.value
        if path.isEmpty || path == "/" || path.hasSuffix("/open") {
            if let token, !token.isEmpty {
                let gated = ProcessInfo.processInfo.environment["CORTEX_UNIVERSE_CONTRACT"] == "1"
                print("[CORTEX-UNIVERSE] handoff rejected: \(gated ? "redeem requires live contract" : "server verification is not available")")
            }
            return
        }
        print("[CORTEX-UNIVERSE] handoff rejected: \(token?.isEmpty == false ? "server verification is not available" : "missing handoff token")")
    }
}
