import SwiftUI

struct AppIntroConfig {
    let appKey: String
    let title: String
    let subtitle: String
    let identity: String
    let statusText: String
    let accentColor: Color
    let secondaryColor: Color
    let imageName: String
    let videoResourceName: String?
    let enterY: Double
    let posterDownshift: CGFloat
    let posterHasEmbeddedUI: Bool
    let fitMode: Bool

    var defaultsKey: String { "hasSeenIntro_\(appKey)_v4" }

    static let cortex = AppIntroConfig(
        appKey: "CORTEX",
        title: "CORTEX",
        subtitle: "CENTRAL OPERATIONAL RESPONSE\n& TACTICAL EXECUTION",
        identity: "INTELLIGENCE OPERATING SYSTEM",
        statusText: "SHELL PREVIEW",
        accentColor: Color(red: 0.0, green: 0.65, blue: 1.0),
        secondaryColor: Color(red: 0.0, green: 0.45, blue: 0.85),
        imageName: "intro_cortex",
        enterY: 0.52,
    posterDownshift: 18,
    posterHasEmbeddedUI: true,
    fitMode: false
    )

    static let signalZero = AppIntroConfig(
        appKey: "SIGNAL_ZERO",
        title: "SIGNAL ZERO",
        subtitle: "NO NOISE.\nJUST TRUTH.",
        identity: "EXECUTION LAYER",
        statusText: "SHELL PREVIEW",
        accentColor: Color(red: 0.0, green: 0.78, blue: 0.92),
        secondaryColor: Color(red: 0.0, green: 0.55, blue: 0.75),
        imageName: "intro_signalzero",
        enterY: 0.50,
    posterDownshift: 18,
    posterHasEmbeddedUI: true,
    fitMode: false
    )

    static let jericho = AppIntroConfig(
        appKey: "JERICHO",
        title: "JERICHO",
        subtitle: "THE WALL.\nTHE SHIELD.",
        identity: "DEFENSE LAYER",
        statusText: "SHELL PREVIEW",
        accentColor: Color(red: 0.95, green: 0.20, blue: 0.15),
        secondaryColor: Color(red: 0.75, green: 0.12, blue: 0.08),
        imageName: "JerichoIntroHero",
        enterY: 0.50,
    posterDownshift: 18,
    posterHasEmbeddedUI: true,
    fitMode: false
    )

    static let prism = AppIntroConfig(
        appKey: "PRISM",
        title: "PRISM",
        subtitle: "THE INTERFACE",
        identity: "CORTEX UNIVERSE",
        statusText: "DRAFT STUDIO",
        accentColor: Color(red: 0.72, green: 0.25, blue: 1.0),
        secondaryColor: Color(red: 0.50, green: 0.12, blue: 0.85),
        imageName: "PRISMIntroHero",
        videoResourceName: "prism-intro-overlay",
        enterY: 0.50,
    posterDownshift: 18,
    posterHasEmbeddedUI: true,
    fitMode: false
    )

    static let cortexNode = AppIntroConfig(
        appKey: "CORTEXNODE",
        title: "CORTEXNODE",
        subtitle: "THE BACKBONE.\nTHE WIRING.",
        identity: "NODE",
        statusText: "SHELL PREVIEW",
        accentColor: Color(red: 0.0, green: 0.55, blue: 1.0),
        secondaryColor: Color(red: 0.0, green: 0.38, blue: 0.82),
        imageName: "CortexNodeIntroHero",
        enterY: 0.625,
    posterDownshift: 18,
    posterHasEmbeddedUI: true,
    fitMode: false
    )

    init(
        appKey: String,
        title: String,
        subtitle: String,
        identity: String,
        statusText: String,
        accentColor: Color,
        secondaryColor: Color,
        imageName: String,
        videoResourceName: String? = nil,
        enterY: Double,
        posterDownshift: CGFloat = 18,
        posterHasEmbeddedUI: Bool = true,
        fitMode: Bool = false
    ) {
        self.appKey = appKey
        self.title = title
        self.subtitle = subtitle
        self.identity = identity
        self.statusText = statusText
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.imageName = imageName
        self.videoResourceName = videoResourceName
        self.enterY = enterY
        self.posterDownshift = posterDownshift
        self.posterHasEmbeddedUI = posterHasEmbeddedUI
        self.fitMode = fitMode
    }
}

// MARK: - First Launch Cinematic Intro View

struct FirstLaunchCinematicIntroView: View {
    let config: AppIntroConfig
    var onComplete: () -> Void

    // Image + depth
    @State private var imageOpacity: Double = 1
    @State private var imageScale: CGFloat = 1.10
    @State private var floatOffset: CGFloat = 0
    @State private var flickerOpacity: Double = 1.0

    // Glow system
    @State private var titleOpacity: Double = 0
    @State private var glowPulse: Bool = false
    @State private var bodyGlowScale: CGFloat = 0.85
    @State private var bodyGlowOpacity: Double = 0

    // ENTER button
    @State private var enterOpacity: Double = 0
    @State private var enterPulse: Bool = false
    @State private var ringRotation: Double = 0
    @State private var innerRingRotation: Double = 0

    // Bottom controls
    @State private var statusOpacity: Double = 0

    // Scan line
    @State private var scanLine: CGFloat = -0.05

    // Transition
    @State private var fadeOut: Bool = false

    // Layout
    @State private var screenSize: CGSize = .zero
    @State private var safeAreaTop: CGFloat = 59

    var body: some View {
        GeometryReader { geo in
            mainContent
                .onAppear {
                    screenSize = geo.size
                    safeAreaTop = geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 59
                }
                .onChange(of: geo.size) { _, s in screenSize = s }
        }
        .ignoresSafeArea()
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Layer 1: Hero image — fit preserves baked-in title below Dynamic Island ──
            CortexIntroHeroStack(
                imageName: config.imageName,
                videoResourceName: config.videoResourceName,
                fitMode: config.fitMode,
                posterDownshift: config.posterDownshift
            )
            .offset(y: floatOffset)
            .ignoresSafeArea()

            // ── Layer 2: Character body aura — matches website card glow ────────
            // Radial bloom in accent color centered on the figure's torso/core
            ZStack {
                // Outer atmosphere — wide, diffuse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                config.accentColor.opacity(glowPulse ? 0.28 : 0.14),
                                config.accentColor.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 220
                        )
                    )
                    .frame(width: 440, height: 440)
                    .blendMode(.screen)

                // Mid bloom — tighter, brighter
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                config.accentColor.opacity(glowPulse ? 0.45 : 0.22),
                                config.accentColor.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .blendMode(.screen)

                // Hot core — sharp center bright point
                Circle()
                    .fill(Color.white.opacity(glowPulse ? 0.08 : 0.03))
                    .blur(radius: 20)
                    .frame(width: 80, height: 80)
                    .blendMode(.screen)
            }
            .scaleEffect(bodyGlowScale)
            .opacity(bodyGlowOpacity)
            .position(x: screenSize.width / 2, y: screenSize.height * 0.50 + config.posterDownshift * 0.85)
            .allowsHitTesting(false)

            // ── Layer 3: Island protection gradient ─────────────────────────────
            // Black at top fades to clear, so Dynamic Island sits clean
            // and character name in art emerges just below it
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.90),
                        Color.black.opacity(0.60),
                        Color.black.opacity(0.18),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: safeAreaTop + 48)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // ── Layer 4: Name glow bloom — behind the baked-in character name ───
            // Positioned just below the Dynamic Island where name appears in art
            if !config.posterHasEmbeddedUI {
                VStack(spacing: 0) {
                    Spacer().frame(height: safeAreaTop + 22 + config.posterDownshift)
                    nameGlowBloom
                    Spacer()
                }
                .opacity(titleOpacity)
                .allowsHitTesting(false)
            }

            // ── Layer 5: Side + corner vignettes ────────────────────────────────
            vignetteLayer

            // ── Layer 6: Scan line sweep ─────────────────────────────────────────
            scanLineLayer

            // ── Layer 7: Bottom gradient — ENTER zone reads clean ───────────────
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: screenSize.height * 0.44)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // ── Layer 8: Bottom status + SKIP ────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()
                bottomControls
                    .padding(.bottom, 52)
            }

            // ── Layer 9: ENTER reactor button ────────────────────────────────────
            if config.posterHasEmbeddedUI {
                Button(action: complete) {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                enterButton
                    .position(
                        x: screenSize.width / 2,
                        y: screenSize.height * config.enterY + config.posterDownshift
                    )
                    .opacity(enterOpacity)
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear {
            ShellIntroMusic.shared.playIfAvailable()
            startAnimations()
        }
    }

    // MARK: - Name Glow Bloom

    private var nameGlowBloom: some View {
        ZStack {
            // Wide atmospheric halo
            Capsule()
                .fill(config.accentColor)
                .opacity(glowPulse ? 0.20 : 0.08)
                .blur(radius: 60)
                .frame(width: screenSize.width * 0.92, height: 110)

            // Mid bloom
            Capsule()
                .fill(config.accentColor)
                .opacity(glowPulse ? 0.38 : 0.16)
                .blur(radius: 24)
                .frame(width: screenSize.width * 0.68, height: 64)

            // White-hot core strip
            Capsule()
                .fill(Color.white.opacity(glowPulse ? 0.14 : 0.05))
                .blur(radius: 8)
                .frame(width: screenSize.width * 0.42, height: 24)

            // Horizontal scan slash across name
            Rectangle()
                .fill(config.accentColor.opacity(glowPulse ? 0.40 : 0.16))
                .blur(radius: 2)
                .frame(width: screenSize.width * 0.72, height: 1.5)
        }
    }

    // MARK: - Vignette Layer

    private var vignetteLayer: some View {
        ZStack {
            // Left edge
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.55), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 72)
                Spacer()
            }
            // Right edge
            HStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.55)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 72)
            }
            // Accent color edge tint — character-colored atmospheric fringe
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [config.accentColor.opacity(0.07), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 60)
                Spacer()
                LinearGradient(
                    colors: [.clear, config.accentColor.opacity(0.07)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 60)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Scan Line

    private var scanLineLayer: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        .clear,
                        config.accentColor.opacity(0.03),
                        config.accentColor.opacity(0.10),
                        config.accentColor.opacity(0.03),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 100)
                .offset(y: geo.size.height * scanLine)
                .blendMode(.screen)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - ENTER Button

    private var enterButton: some View {
        Button(action: complete) {
            ZStack {
                // Outer dashed orbit
                Circle()
                    .stroke(
                        config.accentColor.opacity(0.38),
                        style: StrokeStyle(lineWidth: 1.2, dash: [10, 5])
                    )
                    .frame(width: 196, height: 196)
                    .rotationEffect(.degrees(ringRotation))

                // Inner dashed orbit
                Circle()
                    .stroke(
                        config.secondaryColor.opacity(0.24),
                        style: StrokeStyle(lineWidth: 0.9, dash: [4, 7])
                    )
                    .frame(width: 138, height: 138)
                    .rotationEffect(.degrees(innerRingRotation))

                // Reactor fill
                Circle()
                    .fill(config.accentColor.opacity(enterPulse ? 0.18 : 0.06))
                    .frame(width: 110, height: 110)
                    .scaleEffect(enterPulse ? 1.09 : 0.94)

                // Glow bloom behind ENTER
                Circle()
                    .fill(config.accentColor)
                    .opacity(enterPulse ? 0.26 : 0.09)
                    .blur(radius: 20)
                    .frame(width: 82, height: 82)

                Text("ENTER")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(5)
                    .shadow(color: config.accentColor, radius: 14)
                    .shadow(color: config.accentColor.opacity(0.55), radius: 32)
                    .shadow(color: .white.opacity(0.35), radius: 5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 18) {
            if !config.posterHasEmbeddedUI {
                HStack(spacing: 8) {
                    Circle()
                        .fill(config.accentColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: config.accentColor, radius: 5)
                    Text(config.statusText)
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundColor(config.accentColor)
                        .tracking(3)
                        .shadow(color: config.accentColor.opacity(0.7), radius: 8)
                }
                .opacity(statusOpacity)
            }

            if !fadeOut {
                Button(action: complete) {
                    Text("SKIP")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.22))
                        .tracking(5)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("intro-skip")
                .opacity(statusOpacity)
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Image reveal + Ken Burns zoom out
        withAnimation(.easeOut(duration: 8.5)) { imageScale = 1.0 }

        // Floating depth — subtle vertical drift
        withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true)) {
            floatOffset = -6.0
        }

        // Boot-up flicker — 3 rapid dips then stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.07)) { flickerOpacity = 0.52 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeInOut(duration: 0.07)) { flickerOpacity = 1.00 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                    withAnimation(.easeInOut(duration: 0.05)) { flickerOpacity = 0.80 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.easeInOut(duration: 0.12)) { flickerOpacity = 1.00 }
                    }
                }
            }
        }

        // Body aura glow — blooms in at 0.4s
        withAnimation(.easeOut(duration: 1.4).delay(0.4)) {
            bodyGlowOpacity = 1.0
            bodyGlowScale = 1.0
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.8)) {
            bodyGlowScale = 1.08
        }

        // Scan line
        withAnimation(.easeInOut(duration: 2.8).delay(0.3)) { scanLine = 1.22 }

        // Orbital rings counter-rotate
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { ringRotation = 360 }
        withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) { innerRingRotation = -360 }

        // Name glow bloom at 0.5s
        if !config.posterHasEmbeddedUI {
            withAnimation(.easeIn(duration: 0.9).delay(0.5)) { titleOpacity = 1.0 }
        }

        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.7)) {
            glowPulse = true
        }

        if config.posterHasEmbeddedUI {
            enterOpacity = 1.0
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.5)) {
                enterPulse = true
            }
        } else {
            // ENTER at 2.0s
            withAnimation(.easeIn(duration: 0.7).delay(2.0)) { enterOpacity = 1.0 }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(2.2)) {
                enterPulse = true
            }

            // Status + SKIP at 3.0s
            withAnimation(.easeIn(duration: 0.6).delay(3.0)) { statusOpacity = 1.0 }
        }
    }

    // MARK: - Completion

    private func complete() {
        guard !fadeOut else { return }
        withAnimation(.easeIn(duration: 0.4)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onComplete() }
    }
}

// MARK: - Previews

#Preview("CORTEX") {
    FirstLaunchCinematicIntroView(config: .cortex) {}
}

#Preview("SIGNAL ZERO") {
    FirstLaunchCinematicIntroView(config: .signalZero) {}
}

#Preview("JERICHO") {
    FirstLaunchCinematicIntroView(config: .jericho) {}
}

#Preview("PRISM") {
    FirstLaunchCinematicIntroView(config: .prism) {}
}

#Preview("CORTEXNODE") {
    FirstLaunchCinematicIntroView(config: .cortexNode) {}
}
