import SwiftUI

enum ShellVisualTheme: String, CaseIterable, Identifiable {
    case futuristic
    case classy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .futuristic: return "Futuristic"
        case .classy: return "Classy"
        }
    }
}

struct ShellThemePalette {
    let background: Color
    let backgroundElevated: Color
    let accent: Color
    let accentSoft: Color
    let textPrimary: Color
    let textSecondary: Color
    let glassStroke: Color
    let success: Color
    let warning: Color
    let error: Color
    let offline: Color
    let titleFont: Font
    let bodyFont: Font
    let captionFont: Font
    let glowIntensity: Double
    let usesScanlines: Bool
    let usesNeuralMesh: Bool
    let panelCornerRadius: CGFloat

    static func palette(for theme: ShellVisualTheme, accent baseAccent: Color) -> ShellThemePalette {
        switch theme {
        case .futuristic:
            return ShellThemePalette(
                background: Color(red: 0.016, green: 0.031, blue: 0.063),
                backgroundElevated: Color.white.opacity(0.04),
                accent: baseAccent,
                accentSoft: baseAccent.opacity(0.55),
                textPrimary: Color(red: 0.92, green: 0.95, blue: 0.98),
                textSecondary: Color(red: 0.58, green: 0.64, blue: 0.72),
                glassStroke: baseAccent.opacity(0.22),
                success: Color(red: 0.22, green: 0.78, blue: 0.45),
                warning: Color(red: 0.98, green: 0.68, blue: 0.12),
                error: Color(red: 0.94, green: 0.27, blue: 0.27),
                offline: Color(red: 0.35, green: 0.38, blue: 0.42),
                titleFont: .system(size: 22, weight: .black, design: .monospaced),
                bodyFont: .system(size: 14, weight: .medium, design: .monospaced),
                captionFont: .system(size: 10, weight: .bold, design: .monospaced),
                glowIntensity: 1.0,
                usesScanlines: true,
                usesNeuralMesh: true,
                panelCornerRadius: 14
            )
        case .classy:
            return ShellThemePalette(
                background: Color(red: 0.06, green: 0.07, blue: 0.11),
                backgroundElevated: Color.white.opacity(0.06),
                accent: baseAccent.opacity(0.85),
                accentSoft: baseAccent.opacity(0.4),
                textPrimary: Color(red: 0.94, green: 0.94, blue: 0.96),
                textSecondary: Color(red: 0.62, green: 0.64, blue: 0.70),
                glassStroke: Color.white.opacity(0.12),
                success: Color(red: 0.35, green: 0.72, blue: 0.52),
                warning: Color(red: 0.85, green: 0.62, blue: 0.28),
                error: Color(red: 0.82, green: 0.38, blue: 0.38),
                offline: Color(red: 0.42, green: 0.44, blue: 0.48),
                titleFont: .system(size: 24, weight: .semibold, design: .default),
                bodyFont: .system(size: 15, weight: .regular, design: .default),
                captionFont: .system(size: 11, weight: .medium, design: .default),
                glowIntensity: 0.42,
                usesScanlines: false,
                usesNeuralMesh: false,
                panelCornerRadius: 18
            )
        }
    }

    func orbColor(for state: ShellOrbState) -> Color {
        switch state {
        case .idle: return accentSoft
        case .listening: return accent
        case .thinking: return Color(red: 0.42, green: 0.58, blue: 1.0)
        case .speaking: return Color(red: 0.55, green: 0.96, blue: 1.0)
        case .executing: return accent
        case .success: return success
        case .warning: return warning
        case .error: return error
        case .offline: return offline
        }
    }
}
