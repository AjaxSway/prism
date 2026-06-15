import SwiftUI

struct ShellLaunchView: View {
    let config: PremiumShellConfig
    var onEnter: () -> Void

    private var palette: ShellThemePalette {
        ShellThemePalette.palette(for: .futuristic, accent: config.accent)
    }

    var body: some View {
        ZStack {
            ShellScreenBackground(palette: palette)
            VStack(spacing: 28) {
                Spacer()
                VStack(spacing: 8) {
                    Text(config.displayName)
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .foregroundColor(palette.textPrimary)
                        .tracking(4)
                    Text(config.alias)
                        .font(palette.captionFont)
                        .foregroundColor(palette.accent)
                        .tracking(6)
                    Text(config.ecosystemSubtitle.uppercased())
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                        .tracking(2)
                        .multilineTextAlignment(.center)
                }
                Text(config.identityLine)
                    .font(palette.bodyFont)
                    .foregroundColor(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                ShellStatusBadge(text: "Shell Preview · Enter to continue", palette: palette)
                Button(action: onEnter) {
                    Text("ENTER")
                        .font(palette.captionFont)
                        .tracking(3)
                        .foregroundColor(palette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
