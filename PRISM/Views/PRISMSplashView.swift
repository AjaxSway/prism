import SwiftUI
import AVFoundation

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(red: Double((rgb >> 16) & 0xFF)/255, green: Double((rgb >> 8) & 0xFF)/255, blue: Double(rgb & 0xFF)/255)
    }
}

struct PRISMSplashView: View {
    var onComplete: () -> Void

    @State private var imageOpacity: Double = 0.0
    @State private var imageScale: CGFloat = 1.08
    @State private var glowPulse = false
    @State private var ringRotation: Double = 0
    @State private var innerRingRotation: Double = 0
    @State private var typedCount = 0
    @State private var subtitleOpacity: Double = 0
    @State private var coreGlow: Double = 0
    @State private var scanLine: CGFloat = -0.1
    @State private var fadeOut = false

    private let accent = Color(hex: "9B30FF")
    private let accentBright = Color(hex: "C880FF")
    private let titleLetters = Array("PRISM")
    private let subtitle = "ONE SIGNAL. EVERY CHANNEL."
    private let designator = "— PRISM —"
    private let typeInterval: TimeInterval = 0.10

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                UniverseStarfieldLite(accent: accentBright)
                UniverseFilmGrainOverlay()
                UniverseCinematicVignette()

                CortexIntroPosterImage(
                    imageName: "PRISMIntroHero",
                    fitMode: true,
                    scale: imageScale,
                    opacity: imageOpacity,
                    verticalNudge: 0.02
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.1), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height * 0.2)
                    Spacer()
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.5), Color.black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height * 0.14)
                }
                .ignoresSafeArea()

                Rectangle()
                    .fill(LinearGradient(colors: [.clear, accent.opacity(0.04), accent.opacity(0.08), accent.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
                    .offset(y: geo.size.height * scanLine)
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                Button { enterApp() } label: {
                    ZStack {
                        Circle()
                            .stroke(accent.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(ringRotation))
                        Circle()
                            .stroke(accentBright.opacity(0.15), style: StrokeStyle(lineWidth: 0.8, dash: [3, 5]))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(innerRingRotation))
                        Circle()
                            .fill(accent.opacity(glowPulse ? 0.14 : 0.04))
                            .frame(width: 120, height: 120)
                        Text("ENTER")
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(5)
                            .shadow(color: accent, radius: 8)
                            .shadow(color: accent.opacity(0.5), radius: 18)
                            .opacity(subtitleOpacity)
                    }
                }
                .buttonStyle(.plain)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.53)
                .opacity(coreGlow)

                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    HStack(spacing: 2) {
                        ForEach(0..<titleLetters.count, id: \.self) { i in
                            Text(String(titleLetters[i]))
                                .font(.system(size: 60, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(i < typedCount ? 1 : 0)
                                .scaleEffect(i < typedCount ? 1 : 0.5)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: typedCount)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.6)

                    Spacer().frame(height: 8)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundColor(accentBright)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .opacity(subtitleOpacity)

                    Spacer().frame(height: 6)

                    Text(designator)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(accentBright)
                        .tracking(6)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .opacity(subtitleOpacity)

                    Spacer()

                    UniverseLuxuryStatusLine(text: "BROADCAST READY", accent: accent)
                        .opacity(subtitleOpacity)

                    Button { enterApp() } label: {
                        Text("SKIP")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(3)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .opacity(subtitleOpacity)

                    Spacer().frame(height: 32)
                }

                UniverseHUDCorners(color: accent)
            }
            .opacity(fadeOut ? 0 : 1)
            .onAppear { runBootSequence() }
        }
    }

    private func enterApp() {
        withAnimation(.easeIn(duration: 0.3)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onComplete() }
    }

    private func runBootSequence() {
        withAnimation(.easeOut(duration: 1.2)) { imageOpacity = 1; imageScale = 1.0 }
        withAnimation(.easeOut(duration: 1.5)) { coreGlow = 1 }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { ringRotation = 360 }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { innerRingRotation = -360 }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { glowPulse = true }
        withAnimation(.easeInOut(duration: 2.2)) { scanLine = 1.1 }

        for i in 0...titleLetters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * typeInterval) {
                typedCount = i
            }
        }
        let end = 0.8 + Double(titleLetters.count) * typeInterval + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + end) {
            withAnimation(.easeIn(duration: 0.5)) { subtitleOpacity = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            guard !fadeOut else { return }
            enterApp()
        }
    }
}
