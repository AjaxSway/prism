import SwiftUI

/// God Mode intro — theme on launch · video + Adam welcome · still poster + loading · ENTER.
struct ShellPosterSplashView: View {
    let config: PremiumShellConfig
    var onComplete: () -> Void

    private enum Phase { case video, stillLoading }

    @State private var phase: Phase = .video
    @State private var videoReady = false
    @State private var glowPulse = false
    @State private var scanLine: CGFloat = -0.1
    @State private var fadeOut = false
    @State private var loadingPhase = 0
    @State private var hudOpacity: Double = 0
    @State private var enterVisible = false
    @State private var safeTop: CGFloat = 59

    private var loadingLines: [String] {
        [
            "Initializing shell preview…",
            "Loading local systems…",
            config.introStatusTitle
        ]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                UniverseStarfieldLite(accent: config.accent)
                    .opacity(0.4)

                switch phase {
                case .video:
                    if let videoName = config.introVideoResourceName {
                        ShellIntroVideoPlayer(
                            videoName: videoName,
                            onReady: {
                                videoReady = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    ShellIntroWelcomeVoice.shared.play()
                                }
                            },
                            onFinish: { revealStillPhase() }
                        )
                        .ignoresSafeArea()
                        .opacity(videoReady ? 1 : 0)
                    } else {
                        Color.black.onAppear { revealStillPhase() }
                    }

                case .stillLoading:
                    stillPosterLayer
                    loadingChrome(in: geo)
                }

                topControls(in: geo)
                UniverseHUDCorners(color: config.accent)
            }
            .opacity(fadeOut ? 0 : 1)
            .onAppear {
                safeTop = geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 59
                ShellIntroMusic.shared.ensurePlaying()
            }
        }
    }

    private var stillPosterLayer: some View {
        ZStack {
            CortexIntroPosterImage(
                imageName: config.introHeroImageName,
                fitMode: false,
                posterDownshift: 52
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.black, .black.opacity(0.94), .black.opacity(0.55), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: safeTop + 130)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func loadingChrome(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.55), Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geo.size.height * 0.38)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)

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

        VStack(spacing: 0) {
            Spacer()
            splashLoadingHUD
                .padding(.bottom, geo.safeAreaInsets.bottom + 120)
            if enterVisible {
                enterButton
                    .padding(.bottom, geo.safeAreaInsets.bottom + 36)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .opacity(hudOpacity)
    }

    @ViewBuilder
    private func topControls(in geo: GeometryProxy) -> some View {
        VStack {
            HStack {
                ShellIntroMusicToggle(accent: config.accent)
                Spacer()
                Button("SKIP") { skipTapped() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.78))
                    .tracking(3)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, safeTop + 8)
            Spacer()
        }
    }

    private var enterButton: some View {
        Button(action: enterApp) {
            Text("ENTER")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.92))
                .tracking(5)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .overlay(Capsule().stroke(config.accent.opacity(0.45), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private var splashLoadingHUD: some View {
        SplashLoadingHUD(
            config: config,
            loadingPhase: loadingPhase,
            loadingLines: loadingLines,
            glowPulse: glowPulse
        )
    }

    private func revealStillPhase() {
        withAnimation(.easeInOut(duration: 0.35)) { phase = .stillLoading }
        runBootSequence()
    }

    private func skipTapped() {
        ShellIntroWelcomeVoice.shared.stop()
        if phase == .video {
            revealStillPhase()
        } else {
            enterApp()
        }
    }

    private func enterApp() {
        guard !fadeOut else { return }
        ShellIntroWelcomeVoice.shared.stop()
        withAnimation(.easeIn(duration: 0.32)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) { onComplete() }
    }

    private func runBootSequence() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glowPulse = true }
        withAnimation(.easeInOut(duration: 2.4)) { scanLine = 1.12 }
        withAnimation(.easeIn(duration: 0.5)) { hudOpacity = 1 }

        for i in 0..<loadingLines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.55) {
                loadingPhase = i
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.45)) { enterVisible = true }
        }
    }
}

/// Isolated from ShellPosterSplashView's body so the perpetual glowPulse animation
/// only invalidates these three small dots, not the surrounding gradient-filled
/// layers — mixing them in one view-builder function forced RenderBox to
/// re-rasterize the vignette/scanline gradients every animation frame forever,
/// pinning the main thread and starving touch input (Simulator software-render path).
private struct SplashLoadingHUD: View {
    let config: PremiumShellConfig
    let loadingPhase: Int
    let loadingLines: [String]
    let glowPulse: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == loadingPhase % 3 ? config.accent : config.accentDeep.opacity(0.35))
                        .frame(width: 6, height: 6)
                        .scaleEffect(glowPulse && i == loadingPhase % 3 ? 1.25 : 1)
                }
            }
            Text(loadingLines[min(loadingPhase, loadingLines.count - 1)])
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.78))
                .animation(.easeInOut(duration: 0.35), value: loadingPhase)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(config.accent.opacity(0.28), lineWidth: 1))
        )
    }
}
