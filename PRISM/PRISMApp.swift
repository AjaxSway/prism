import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct PRISMApp: App {
    @State private var showSplash = true

    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                PRISMRootView()
                    .preferredColorScheme(.dark)

                if showSplash {
                    PRISMSplashView {
                        withAnimation(.easeOut(duration: 0.7)) { showSplash = false }
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 1.03))))
                    .zIndex(100)
                }
            }
            .onChange(of: showSplash) { _, visible in
                if !visible { fireIntroSpeech() }
            }
        }
    }

    private func fireIntroSpeech() {
        guard !UserDefaults.standard.bool(forKey: "prism.introPlayed") else { return }
        UserDefaults.standard.set(true, forKey: "prism.introPlayed")
        let text = "PRISM online. Distribution layer activated. One signal in. Every channel out. I am the broadcast intelligence of the CORTEX universe. I don't just post content — I architect distribution. I understand the cultural grammar of every platform. I route your message precisely to where it will land with maximum impact. Nothing leaves without operator approval. Every word earns its place. Every post is a deliberate move. PRISM. One signal. Every channel. Zero noise."
        VoiceService.speak(text)
    }
}
