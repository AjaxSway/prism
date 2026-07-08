#if canImport(AppIntents)
import AppIntents

@available(iOS 16.0, *)
struct OpenPrismIntent: AppIntent {
    static var title: LocalizedStringResource = "Open PRISM"
    static var description = IntentDescription("Open PRISM")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 16.0, *)
struct PrismShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenPrismIntent(),
            phrases: ["Open PRISM in \(.applicationName)"],
            shortTitle: "Open PRISM",
            systemImageName: "sparkles"
        )
    }
}
#endif
