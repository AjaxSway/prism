import SwiftUI

struct ShellGlassPanel<Content: View>: View {
    let palette: ShellThemePalette
    var livingBorder: Bool = false
    var livingSecondary: Color? = nil
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
            .overlay {
                if livingBorder {
                    PrismLivingBorder(accent: palette.accent, secondary: livingSecondary, cornerRadius: 12)
                }
            }
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
    var accentTint: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let tint = accentTint {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(tint)
                    .frame(width: 3, height: 28)
            }
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentTint ?? palette.accentSoft)
            Text(line)
                .font(palette.captionFont)
                .foregroundColor(accentTint != nil ? .white.opacity(0.65) : palette.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            accentTint != nil
                ? AnyView(palette.backgroundElevated.overlay(accentTint!.opacity(0.08)))
                : AnyView(palette.backgroundElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentTint?.opacity(0.35) ?? palette.glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ShellModuleCard: View {
    let module: ShellModuleDefinition
    let palette: ShellThemePalette
    var livingMotion: Bool = false

    var body: some View {
        let card = ShellGlassPanel(palette: palette, livingBorder: livingMotion, livingSecondary: Color(red: 0.925, green: 0.286, blue: 0.600)) {
            HStack(spacing: 12) {
                ZStack {
                    if livingMotion {
                        Circle()
                            .fill(palette.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        PrismPulseRing(color: palette.accent, diameter: 38, lineWidth: 0.8, speed: 0.85)
                        PrismModuleGlyphView(
                            moduleId: module.id,
                            accent: palette.accent,
                            secondary: Color(red: 0.925, green: 0.286, blue: 0.600),
                            size: 32
                        )
                    } else {
                        Image(systemName: module.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.accent)
                            .frame(width: 32)
                    }
                }
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
                    text: moduleBadgeText,
                    palette: palette,
                    tone: module.availability == .locked ? .warning : .neutral
                )
            }
        }

        if livingMotion {
            card.prismLivingCard(accent: palette.accent)
        } else {
            card
        }
    }

    private var moduleBadgeText: String {
        switch module.availability {
        case .locked: return "Locked"
        case .preview: return "Preview"
        }
    }
}

struct ShellEmptyState: View {
    let palette: ShellThemePalette
    let title: String
    let message: String
    let icon: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

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
            if let actionTitle, let action {
                ShellPrimaryButton(title: actionTitle, palette: palette, action: action)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

struct ShellPrimaryButton: View {
    let title: String
    let palette: ShellThemePalette
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Text(title.uppercased())
                .font(palette.captionFont)
                .tracking(2)
                .foregroundColor(disabled ? palette.textSecondary : palette.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(disabled ? palette.backgroundElevated : palette.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(disabled ? palette.glassStroke : Color.clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ShellPressableButtonStyle())
    }
}

struct ShellScreenBackground: View {
    let palette: ShellThemePalette
    var appKind: ShellAppKind? = nil

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            if appKind == .prism {
                ShellAppAmbientLayer(appKind: .prism, accent: palette.accent, theme: .futuristic)
                    .ignoresSafeArea()
            }
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

/// Compact on/off control for intro and quick access.
struct ShellIntroMusicToggle: View {
    @Bindable private var music = ShellIntroMusic.shared
    var accent: Color
    var secondary: Color = .white.opacity(0.7)

    var body: some View {
        Button {
            music.isEnabled.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: music.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(music.isEnabled ? "Music on" : "Music off")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(music.isEnabled ? accent : secondary.opacity(0.65))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.45))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(accent.opacity(music.isEnabled ? 0.45 : 0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(music.isEnabled ? "Background music on" : "Background music off")
    }
}
