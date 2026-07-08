import SwiftUI
import UIKit

@MainActor
@Observable
final class ShellEnvironment {
    let config: PremiumShellConfig
    var theme: ShellVisualTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: config.themeStorageKey) }
    }
    var orbState: ShellOrbState = .offline
    var selectedTab: ShellTab = .home
    let activityStore: ShellActivityStore
    let imageHistory = ImageHistoryStore()
    let draftStore: PrismLocalDraftStore

    var palette: ShellThemePalette {
        ShellThemePalette.palette(for: theme, accent: config.accent)
    }

    var shellStatusLine: String {
        let count = draftStore.drafts.count
        if count == 0 { return "Draft studio · \(config.displayName) · local saves on device" }
        return "\(count) local draft\(count == 1 ? "" : "s") · approval-gated · no live publish"
    }

    let brain = ShellBrainGateway.shared

    init(config: PremiumShellConfig) {
        self.config = config
        self.activityStore = ShellActivityStore(storageKey: "\(config.storagePrefix).activity.v1")
        self.draftStore = PrismLocalDraftStore(storagePrefix: config.storagePrefix)
        if let raw = UserDefaults.standard.string(forKey: config.themeStorageKey),
           let saved = ShellVisualTheme(rawValue: raw) {
            theme = saved
        } else {
            theme = .futuristic
        }
        if activityStore.events.isEmpty {
            seedInitialActivity()
        }
        orbState = .idle
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["SHELL_TAB"],
           let t = ShellTab(rawValue: raw) {
            selectedTab = t
        }
        #endif
    }

    func resetMockData() {
        activityStore.reset()
        imageHistory.reset()
        draftStore.reset()
        seedInitialActivity()
        orbState = .idle
        showToast("Local data reset", detail: "Drafts, activity, and gallery cleared", tone: .warning)
    }

    func demoOrbCycle() {
        if ShellFeatureFlags.brainConnected {
            selectedTab = .command
            showToast("Command Center", detail: "Super Brain route · enter a prompt", tone: .info)
            return
        }
        guard orbState != .offline else { return }
        let sequence: [ShellOrbState] = [.listening, .thinking, .speaking, .executing, .success, .idle]
        Task {
            for state in sequence {
                try? await Task.sleep(for: .milliseconds(900))
                orbState = state
            }
            activityStore.append(title: "Orb demo", detail: "State cycle completed locally", kind: .info)
        }
    }

    func openPrimaryModule() {
        selectedTab = .home
        if config.appKind == .prism {
            showToast("Signal Composer", detail: "Write your source signal on home, then queue refraction", tone: .info)
        } else if let primary = config.modules.first(where: { $0.id == config.primaryModuleId }) {
            openModule(primary)
        } else {
            selectedTab = .modules
        }
    }

    func openModule(_ module: ShellModuleDefinition) {
        pendingModuleOpen = module
        selectedTab = .modules
        activityStore.append(title: module.title, detail: module.subtitle, kind: .navigation)
    }

    var pendingModuleOpen: ShellModuleDefinition?

    var toast: ShellToast?
    var connectSheet: ShellConnectSheetPayload?
    var activeBriefing: ShellBriefingPayload?
    var shareSheet: ShellSharePayload?
    var showSubscriptionPlans = false
    private var toastDismissTask: Task<Void, Never>?

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func showToast(_ title: String, detail: String, icon: String? = nil, tone: ShellToastTone = .info) {
        toastDismissTask?.cancel()
        impact(.light)
        toast = ShellToast(title: title, detail: detail, icon: icon ?? tone.icon, tone: tone)
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    func presentChannelConnect(_ account: MockPrismAccount) {
        presentConnectLater(
            account.name,
            detail: "\(account.name) is not authorized yet. Draft, approve, and share locally until OAuth provisioning is enabled.",
            steps: [
                "Tap Connect when operator OAuth is live.",
                "Complete platform authorization in the secure flow.",
                "Until then, use Approval Gate and Share draft for export.",
            ]
        )
    }

    func presentConnectLater(_ feature: String, detail: String? = nil, steps: [String]? = nil) {
        impact(.medium)
        connectSheet = ShellConnectSheetPayload(
            feature: feature,
            detail: detail ?? "Cloud publish and OAuth unlock in a future update.",
            steps: steps ?? [
                "Finish draft review in Approval Gate.",
                "Export or share locally today.",
                "Live platform publish requires operator OAuth setup.",
            ]
        )
    }

    func presentShare(text: String, imageName: String? = nil) {
        impact(.light)
        shareSheet = ShellSharePayload(text: text, imageName: imageName)
        activityStore.append(title: "Share sheet", detail: text.prefix(60).description, kind: .info)
    }

    func saveDraftPreview(module: String, snippet: String) {
        impact(.light)
        if config.appKind == .prism, !snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = draftStore.saveComposerDraft(sourceText: snippet)
        }
        showToast("Draft saved", detail: "\(module) · stored on device", tone: .success)
        activityStore.append(title: "Draft saved", detail: snippet.prefix(120).description, kind: .info)
    }

    func exportDraftText(_ text: String, label: String) {
        presentShare(text: text, imageName: nil)
        showToast(label, detail: "Share sheet opened · local export", tone: .success)
    }

    func attachProofAsset(_ assetName: String, draftID: UUID? = nil) {
        draftStore.attachProof(assetName, to: draftID)
        showToast("Proof attached", detail: assetName, tone: .success)
    }

    func runLocalCommand(_ command: String) -> String {
        if config.appKind == .prism {
            return draftStore.localCommandResponse(for: command)
        }
        return "[Preview] \(config.displayName) received: \(command.prefix(120))…"
    }

    private func seedInitialActivity() {
        activityStore.append(
            title: "\(config.displayName) initialized",
            detail: "Draft studio initialized · local saves on device",
            kind: .info
        )
    }
}

struct ShellSharePayload: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let imageName: String?
}
