import SwiftUI

/// Every-launch cinematic splash — same lane as FORGE `ForgeSplashView`, driven by shell config + poster asset.
struct ShellPosterSplashView: View {
    let config: PremiumShellConfig
    var onComplete: () -> Void

    @State private var imageOpacity: Double = 0
    @State private var imageScale: CGFloat = 1.08
    @State private var glowPulse = false
    @State private var ringRotation: Double = 0
    @State private var innerRingRotation: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var coreGlow: Double = 0
    @State private var scanLine: CGFloat = -0.1
    @State private var fadeOut = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                UniverseStarfieldLite(accent: config.accent)
                UniverseFilmGrainOverlay()
                UniverseCinematicVignette()

                CortexIntroPosterImage(
                    imageName: config.introHeroImageName,
                    fitMode: true,
                    scale: imageScale,
                    opacity: imageOpacity,
                    verticalNudge: 0.02
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(0.65), Color.black.opacity(0.12), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.22)
                    Spacer()
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.55), Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.18)
                }
                .ignoresSafeArea()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, config.accent.opacity(0.06), config.accentDeep.opacity(0.1), config.accent.opacity(0.06), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 72)
                    .offset(y: geo.size.height * scanLine)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                Button { enterApp() } label: {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                VStack(spacing: 0) {
                    Spacer()
                    Button { enterApp() } label: {
                        Text("SKIP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.38))
                            .tracking(3)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .opacity(subtitleOpacity)
                    Spacer().frame(height: 34)
                }

                UniverseHUDCorners(color: config.accent)
            }
            .opacity(fadeOut ? 0 : 1)
            .onAppear { runBootSequence() }
        }
    }

    private func enterApp() {
        withAnimation(.easeIn(duration: 0.32)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { onComplete() }
    }

    private func runBootSequence() {
        withAnimation(.easeOut(duration: 1.1)) { imageOpacity = 1; imageScale = 1 }
        withAnimation(.easeOut(duration: 1.4)) { coreGlow = 1 }
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { ringRotation = 360 }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { innerRingRotation = -360 }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glowPulse = true }
        withAnimation(.easeInOut(duration: 2.4)) { scanLine = 1.12 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 0.55)) { subtitleOpacity = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 40) {
            guard !fadeOut else { return }
            enterApp()
        }
    }
}
