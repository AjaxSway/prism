import SwiftUI

@MainActor
@Observable
final class ShellEnvironment {
    let config: PremiumShellConfig
    var theme: ShellVisualTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: config.themeStorageKey) }
    }
    var orbState: ShellOrbState = .offline
    var selectedTab: ShellTab = .home
    let activityStore = ShellActivityStore()
    let imageHistory = ImageHistoryStore()

    var palette: ShellThemePalette {
        ShellThemePalette.palette(for: theme, accent: config.accent)
    }

    var shellStatusLine: String {
        let gateway = ShellBrainGateway.shared
        if gateway.isLive { return "Connected · CORTEX backbone" }
        if ShellFeatureFlags.brainConnected { return gateway.statusDetail }
        return "Shell Preview · Offline · Connect later"
    }

    let brain = ShellBrainGateway.shared

    init(config: PremiumShellConfig) {
        self.config = config
        if let raw = UserDefaults.standard.string(forKey: config.themeStorageKey),
           let saved = ShellVisualTheme(rawValue: raw) {
            theme = saved
        } else {
            theme = .futuristic
        }
        seedInitialActivity()
        orbState = .idle
    }

    func resetMockData() {
        activityStore.reset()
        imageHistory.reset()
        seedInitialActivity()
        orbState = .idle
    }

    func demoOrbCycle() {
        guard orbState != .offline else { return }
        let sequence: [ShellOrbState] = [.listening, .thinking, .speaking, .executing, .success, .idle]
        Task {
            for state in sequence {
                try? await Task.sleep(for: .milliseconds(900))
                orbState = state
            }
            activityStore.append(
                title: "Orb state demo",
                detail: "Mock state cycle completed — no live execution.",
                kind: .info
            )
        }
    }

    func openPrimaryModule() {
        if let primary = config.modules.first(where: { $0.id == config.primaryModuleId }) {
            openModule(primary)
        } else {
            selectedTab = .modules
        }
    }

    func openModule(_ module: ShellModuleDefinition) {
        pendingModuleOpen = module
        selectedTab = .modules
        activityStore.append(
            title: "\(module.title) opened",
            detail: "Shell preview navigation — mock topology only.",
            kind: .navigation
        )
    }

    var pendingModuleOpen: ShellModuleDefinition?

    private func seedInitialActivity() {
        activityStore.append(
            title: "Shell initialized",
            detail: "\(config.displayName) shell V1 · offline preview · mock data only.",
            kind: .info
        )
    }
}
