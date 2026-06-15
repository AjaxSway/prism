import SwiftUI

/// Shared shell intro — poster hero, subtle arc, ENTER below arc, no top overlay text.
struct ShellCinematicIntroView: View {
    let config: PremiumShellConfig
    var onEnter: () -> Void

    @State private var imageOpacity = 0.0
    @State private var imageScale: CGFloat = 1.06
    @State private var arcPulse = false
    @State private var arcFlash = false
    @State private var ringRotation: Double = 0
    @State private var statusVisible = false
    @State private var fadeOut = false
    @State private var safeTop: CGFloat = 59

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                ShellIntroEnergyWash(accent: config.accent, appKind: config.appKind)
                    .ignoresSafeArea()

                CortexIntroPosterImage(
                    imageName: config.introHeroImageName,
                    fitMode: false,
                    scale: imageScale,
                    opacity: imageOpacity,
                    verticalNudge: 0,
                    posterDownshift: 12
                )
                .ignoresSafeArea()

                // Mask baked-in duplicate title band at top of artwork only
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black, .black.opacity(0.94), .black.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: safeTop + 130)
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                arcEnterControl
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.595)

                VStack {
                    Spacer()
                    bottomStatus
                        .padding(.bottom, 46)
                }

                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.88), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.28)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .opacity(fadeOut ? 0 : 1)
            .onAppear {
                safeTop = geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 59
                startMotion()
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var arcEnterControl: some View {
        Button(action: enterTapped) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(
                            config.accent.opacity(arcFlash ? 0.62 : (arcPulse ? 0.38 : 0.24)),
                            lineWidth: arcFlash ? 1.6 : 1.1
                        )
                        .frame(width: 164, height: 164)

                    Circle()
                        .stroke(
                            config.accentDeep.opacity(arcPulse ? 0.22 : 0.10),
                            style: StrokeStyle(lineWidth: 0.8, dash: [7, 9])
                        )
                        .frame(width: 132, height: 132)
                        .rotationEffect(.degrees(ringRotation))

                    ShellAppCoreOrbView(
                        appKind: config.appKind,
                        color: config.accent,
                        secondary: config.refractionPink ?? config.accentDeep,
                        size: 72,
                        intensity: arcPulse ? 1 : 0.7
                    )
                }

                Text("ENTER")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(arcFlash ? 1 : 0.72))
                    .tracking(5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(arcFlash ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.22), value: arcFlash)
    }

    private var bottomStatus: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(config.accent.opacity(statusVisible ? 0.85 : 0.35))
                    .frame(width: 10, height: 10)
                Text(config.introStatusTitle)
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(4)
            }
            .opacity(statusVisible ? 1 : 0)

            Text("Shell preview · Not connected · Tap arc to enter")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.42))
                .tracking(1)
                .opacity(statusVisible ? 1 : 0)
        }
    }

    private func startMotion() {
        withAnimation(.easeOut(duration: 1.4)) { imageOpacity = 1 }
        withAnimation(.easeOut(duration: 7)) { imageScale = 1.0 }
        withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { ringRotation = 360 }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.4)) {
            arcPulse = true
        }
        withAnimation(.easeIn(duration: 0.8).delay(0.9)) { statusVisible = true }
    }

    private func enterTapped() {
        guard !fadeOut else { return }
        arcFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeIn(duration: 0.35)) { fadeOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { onEnter() }
        }
    }
}
