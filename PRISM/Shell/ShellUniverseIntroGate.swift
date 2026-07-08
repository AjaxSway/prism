import SwiftUI

/// Every launch: God Mode intro — theme · video + Adam welcome · still poster · ENTER.
struct ShellUniverseIntroGate<Content: View>: View {
    let shellConfig: PremiumShellConfig
    let introConfig: AppIntroConfig
    @ViewBuilder var content: () -> Content

    @State private var showSplash = true

    private var skipIntroForTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
            || ProcessInfo.processInfo.environment["PRISM_SKIP_INTRO"] == "1"
    }

    init(shellConfig: PremiumShellConfig, introConfig: AppIntroConfig, @ViewBuilder content: @escaping () -> Content) {
        self.shellConfig = shellConfig
        self.introConfig = introConfig
        self.content = content
    }

    var body: some View {
        ZStack {
            content()
                .opacity(showSplash && !skipIntroForTesting ? 0 : 1)
                .allowsHitTesting(!showSplash || skipIntroForTesting)

            if showSplash && !skipIntroForTesting {
                ShellPosterSplashView(config: shellConfig) {
                    withAnimation(.easeOut(duration: 0.55)) { showSplash = false }
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .onAppear {
            ShellIntroMusic.shared.ensurePlaying()
            if skipIntroForTesting { showSplash = false }
        }
    }
}

extension AppIntroConfig {
    static let aurion = AppIntroConfig(
        appKey: "AURION",
        title: "AURION",
        subtitle: "LEGACY COMMAND\nINTELLIGENCE",
        identity: "VICTORY PROTOCOL",
        statusText: "SHELL PREVIEW",
        accentColor: Color(red: 1.0, green: 0.0, blue: 0.25),
        secondaryColor: Color(red: 1.0, green: 0.84, blue: 0.0),
        imageName: "AurionIntroHero",
        enterY: 0.625,
        posterDownshift: 18,
        posterHasEmbeddedUI: true,
        fitMode: false
    )

    static func forShell(_ shell: PremiumShellConfig) -> AppIntroConfig {
        switch shell.appKind {
        case .cortexNode: return .cortexNode
        case .jericho: return .jericho
        case .prism: return .prism
        }
    }
}
