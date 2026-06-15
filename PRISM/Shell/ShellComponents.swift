import SwiftUI

struct ShellGlassPanel<Content: View>: View {
    let palette: ShellThemePalette
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.backgroundElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(palette.glassStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShellStatusBadge: View {
    let text: String
    let palette: ShellThemePalette
    var tone: Tone = .neutral

    enum Tone { case neutral, warning, success }

    var body: some View {
        Text(text.uppercased())
            .font(palette.captionFont)
            .tracking(1)
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(foreground.opacity(0.1))
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch tone {
        case .neutral: return palette.textSecondary
        case .warning: return palette.warning
        case .success: return palette.success
        }
    }
}

struct ShellAuditStrip: View {
    let palette: ShellThemePalette
    let line: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.accentSoft)
            Text(line)
                .font(palette.captionFont)
                .foregroundColor(palette.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(palette.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ShellModuleCard: View {
    let module: ShellModuleDefinition
    let palette: ShellThemePalette

    var body: some View {
        ShellGlassPanel(palette: palette) {
            HStack(spacing: 12) {
                Image(systemName: module.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(palette.bodyFont.weight(.semibold))
                        .foregroundColor(palette.textPrimary)
                    Text(module.subtitle)
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                }
                Spacer()
                ShellStatusBadge(
                    text: module.availability == .locked ? "Connect later" : "Preview",
                    palette: palette,
                    tone: module.availability == .locked ? .warning : .neutral
                )
            }
        }
    }
}

struct ShellEmptyState: View {
    let palette: ShellThemePalette
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(palette.textSecondary.opacity(0.6))
            Text(title)
                .font(palette.titleFont)
                .foregroundColor(palette.textPrimary)
            Text(message)
                .font(palette.bodyFont)
                .foregroundColor(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

struct ShellPrimaryButton: View {
    let title: String
    let palette: ShellThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(palette.captionFont)
                .tracking(2)
                .foregroundColor(palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct ShellScreenBackground: View {
    let palette: ShellThemePalette

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            RadialGradient(
                colors: [palette.accent.opacity(0.12), .clear],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()
        }
    }
}
