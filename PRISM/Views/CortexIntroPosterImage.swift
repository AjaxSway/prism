import SwiftUI

/// Cinematic intro/splash poster layout shared across CORTEX ecosystem apps.
/// `.fit` + safe-area top padding keeps baked-in titles (CORTEX, JERICHO, etc.)
/// visible below the Dynamic Island. `.fill` for full-bleed character art without top text.
struct CortexIntroPosterImage: View {
    let imageName: String
    var fitMode: Bool = true
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    /// Extra downward nudge as fraction of screen height (positive = down).
    var verticalNudge: CGFloat = 0.02
    /// Additional points to shift poster below Dynamic Island / notch.
    var posterDownshift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 59
            let downwardShift = topInset * 0.42 + posterDownshift
            let image = Image(imageName)
                .resizable()
                .interpolation(.high)

            Group {
                if fitMode {
                    image
                        .scaledToFit()
                        .frame(width: geo.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, topInset + 4 + posterDownshift)
                        .padding(.bottom, 28)
                        .offset(y: geo.size.height * verticalNudge)
                } else {
                    image
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .offset(y: downwardShift)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
    }
}
