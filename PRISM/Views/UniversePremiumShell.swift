import SwiftUI

// MARK: - CORTEX Universe Premium Shell Kit
// Million-dollar arrival language — corners, grain, vignette, shimmer.

struct UniverseHUDCorners: View {
    let color: Color
    private let arm: CGFloat = 26
    private let weight: CGFloat = 1.6

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, pad: CGFloat = 18
            ZStack {
                corner(at: .topLeading).position(x: pad + arm / 2, y: pad + arm / 2 + geo.safeAreaInsets.top)
                corner(at: .topTrailing).position(x: w - pad - arm / 2, y: pad + arm / 2 + geo.safeAreaInsets.top)
                corner(at: .bottomLeading).position(x: pad + arm / 2, y: h - pad - arm / 2)
                corner(at: .bottomTrailing).position(x: w - pad - arm / 2, y: h - pad - arm / 2)
            }
        }
        .allowsHitTesting(false)
    }

    private enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func corner(at c: Corner) -> some View {
        Path { p in
            switch c {
            case .topLeading:
                p.move(to: CGPoint(x: 0, y: arm)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: arm, y: 0))
            case .topTrailing:
                p.move(to: CGPoint(x: -arm, y: 0)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: 0, y: arm))
            case .bottomLeading:
                p.move(to: CGPoint(x: 0, y: -arm)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: arm, y: 0))
            case .bottomTrailing:
                p.move(to: CGPoint(x: -arm, y: 0)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: 0, y: -arm))
            }
        }
        .stroke(color.opacity(0.42), style: StrokeStyle(lineWidth: weight, lineCap: .square))
        .frame(width: arm, height: arm)
        .shadow(color: color.opacity(0.35), radius: 6)
    }
}

struct UniverseFilmGrainOverlay: View {
    @State private var seed: Double = 0
    var body: some View {
        Canvas { ctx, size in
            for _ in 0..<900 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let a = Double.random(in: 0.02...0.08)
                let r = CGFloat.random(in: 0.4...1.2)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(a)))
            }
        }
        .blendMode(.overlay)
        .opacity(0.35)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 0.08).repeatForever(autoreverses: true)) { seed += 1 }
        }
    }
}

struct UniverseCinematicVignette: View {
    var body: some View {
        RadialGradient(
            colors: [.clear, .clear, Color.black.opacity(0.45), Color.black.opacity(0.82)],
            center: .center,
            startRadius: 80,
            endRadius: 520
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct UniverseLuxuryStatusLine: View {
    let text: String
    let accent: Color
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, accent.opacity(shimmer ? 0.85 : 0.45), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 260, height: 1)
                .shadow(color: accent.opacity(0.5), radius: 6)
            Text(text)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [.white, accent, .white], startPoint: shimmer ? .leading : .trailing, endPoint: shimmer ? .trailing : .leading)
                )
                .tracking(5)
                .shadow(color: accent.opacity(0.55), radius: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }
}

struct UniverseStarfieldLite: View {
    @State private var twinkle = false
    var accent: Color = .white

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<48 {
                let x = size.width * CGFloat((Double(i * 37 % 100)) / 100.0)
                let y = size.height * CGFloat((Double(i * 53 % 100)) / 100.0)
                let r: CGFloat = i.isMultiple(of: 7) ? 1.6 : 0.9
                let bright = i.isMultiple(of: 5)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color((bright ? accent : .white).opacity(bright ? 0.55 : 0.22))
                )
            }
        }
        .opacity(twinkle ? 1 : 0.72)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { twinkle = true }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Cockpit chrome (persists million-dollar frame after splash)

private struct UniversePremiumChrome: ViewModifier {
    let accent: Color
    var grainOpacity: Double = 0.18
    var vignetteOpacity: Double = 0.42

    func body(content: Content) -> some View {
        content.overlay {
            ZStack {
                UniverseFilmGrainOverlay().opacity(grainOpacity)
                UniverseCinematicVignette().opacity(vignetteOpacity)
                UniverseHUDCorners(color: accent)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func universePremiumChrome(accent: Color, grainOpacity: Double = 0.18, vignetteOpacity: Double = 0.42) -> some View {
        modifier(UniversePremiumChrome(accent: accent, grainOpacity: grainOpacity, vignetteOpacity: vignetteOpacity))
    }
}
