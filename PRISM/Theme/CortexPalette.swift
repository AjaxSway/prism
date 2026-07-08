import SwiftUI

/// CORTEX Brand Palette — Signal Zero Electric Blue on Deep Space Black.
/// Single source of truth. Every view pulls from here.
///
/// Palette is aligned with the Signal Zero brand canon:
///   Primary:    #4090FF (Signal Zero Blue — electric neon blue)
///   Secondary:  #80B8FF (bright blue)
///   Background: #02040a → #070a18 (very dark blue-black, deep space)
///   Text:       #F0F4F8 (white)
///   Dim text:   #B8C2CC
///   Hot Pink:   #FF0080 (execution register, Neon theme primary)
///   Green:      #3CE08A (active/online, Neon theme secondary)
///   Amber:      #F5B947 (warning)
///
/// Almost every color here is a mutable `var` so ThemeManager can swap values
/// when the user switches App Theme (Dark / Light / Scion / Blue / Red / Neon)
/// or HUD Theme. The defaults below are dark-mode Signal Zero values;
/// `ThemeManager.apply()` overrides them on launch and on every theme change.
enum CortexPalette {

    // MARK: - Dynamic Colors (ThemeManager updates these)

    /// Primary accent — changes with HUD theme (Stark, Ember, Matrix, etc.)
    /// Default: Signal Zero Blue #4090FF
    nonisolated(unsafe) static var primary: Color = Color(red: 64/255, green: 144/255, blue: 255/255)

    /// Primary background — changes with App theme (Dark, Light, Scion)
    /// Default: Deep Space Black #02040a
    nonisolated(unsafe) static var background: Color = Color(red: 2/255, green: 4/255, blue: 10/255)

    /// Primary text — changes with App theme (white on dark, near-black on light)
    nonisolated(unsafe) static var text: Color = Color(red: 240/255, green: 244/255, blue: 248/255) // #F0F4F8

    /// UI text for labels/readouts — adapts to theme
    nonisolated(unsafe) static var uiTextAdaptive: Color = Color(red: 64/255, green: 144/255, blue: 255/255)

    // MARK: - Brand Accents (theme-aware)

    /// Bright Blue — highlights, scanning effects, flashes.  Dark: #80B8FF
    nonisolated(unsafe) static var secondary: Color = Color(red: 128/255, green: 184/255, blue: 255/255)

    /// Mid Blue — secondary text, labels, neural connections.
    nonisolated(unsafe) static var neural: Color = Color(red: 96/255, green: 168/255, blue: 230/255)

    /// Signal Zero Blue — numbers, labels, telemetry readouts.  #4090FF
    nonisolated(unsafe) static var uiText: Color = Color(red: 64/255, green: 144/255, blue: 255/255)

    /// Deep Blue — grid lines, orbit rings, interface structure, borders.
    nonisolated(unsafe) static var grid: Color = Color(red: 38/255, green: 86/255, blue: 160/255)

    // MARK: - Backgrounds (theme-aware)

    /// Deep Space — secondary background, panel fills.  Dark: #02040a
    nonisolated(unsafe) static var backgroundDepth: Color = Color(red: 2/255, green: 4/255, blue: 10/255)

    /// Deeper Space — tertiary background, card surfaces.
    nonisolated(unsafe) static var backgroundShadow: Color = Color(red: 10/255, green: 14/255, blue: 32/255)

    /// Card surface — used by panels and rounded cards.  Dark: #02040a
    nonisolated(unsafe) static var surface: Color = Color(red: 2/255, green: 4/255, blue: 10/255)

    // MARK: - Extended Palette (theme-aware)

    /// White text — primary text, emphasis.  Dark: #F0F4F8
    nonisolated(unsafe) static var whiteMist: Color = Color(red: 240/255, green: 244/255, blue: 248/255)

    /// Deep layer — borders, separators, subtle structure.  Dark: #02040a
    nonisolated(unsafe) static var deepTeal: Color = Color(red: 2/255, green: 4/255, blue: 10/255)

    /// Core layer — mid-tone for rings and structure.
    nonisolated(unsafe) static var coreTeal: Color = Color(red: 10/255, green: 14/255, blue: 32/255)

    // MARK: - Glow Gradient (theme-aware)

    /// CORTEX glow stops for radial/linear gradients. Signal Zero Blue cascade.
    nonisolated(unsafe) static var glowGradient: [Color] = [
        Color(red: 128/255, green: 184/255, blue: 255/255),  // #80B8FF bright blue
        Color(red: 64/255,  green: 144/255, blue: 255/255),  // #4090FF Signal Zero Blue
        Color(red: 38/255,  green: 86/255,  blue: 160/255),  // mid blue
        Color(red: 10/255,  green: 24/255,  blue: 64/255)    // deep blue
    ]

    // MARK: - Semantic (stable across themes)

    /// Positive / active / online — Signal Zero Green #3CE08A
    static let positive = Color(red: 60/255, green: 224/255, blue: 138/255)

    /// Negative / down indicator — signal red
    static let negative = Color(red: 1.0, green: 0.3, blue: 0.3)

    /// Warning — Signal Zero Amber #F5B947
    static let warning = Color(red: 245/255, green: 185/255, blue: 71/255)

    /// Critical — red overlay, security/threat only
    static let critical = Color(red: 1.0, green: 0.25, blue: 0.25)

    // MARK: - Muted (theme-aware)

    /// Muted — neutral for idle/inactive states.  Dark: #B8C2CC dim text
    nonisolated(unsafe) static var muted: Color = Color(red: 184/255, green: 194/255, blue: 204/255)

    // MARK: - Surface Accents (per-hub register · 2026-04-30 SVP HUD parity)

    /// Health surface accent — pink-magenta heart register.  #FF3B82
    /// Source: SVP HUD reference (Apple Health dashboard, heart icon + activity ring).
    nonisolated(unsafe) static var healthAccent: Color = Color(red: 255/255, green: 59/255, blue: 130/255)

    /// Tesla surface accent — Tesla brand red.  #E82127
    /// Source: SVP HUD reference (Tesla dashboard, status pill + Sentry mode).
    /// Distinct from `negative`/`critical` — Tesla red is brand chrome, not status semantic.
    nonisolated(unsafe) static var teslaAccent: Color = Color(red: 232/255, green: 33/255, blue: 39/255)

    /// Smart Home primary accent — Signal Zero Blue, aliased from `primary` for hub-view clarity.
    nonisolated(unsafe) static var homeAccent: Color = Color(red: 64/255, green: 144/255, blue: 255/255)

    /// Smart Home security accent — neon green for SECURE / DISARMED states.  #00E676
    /// Source: SVP HUD reference (Smart Home status chips, scene activate links).
    /// Distinct from `positive` — `positive` is data-up semantic, this is brand chrome.
    nonisolated(unsafe) static var homeSecondary: Color = Color(red: 0/255, green: 230/255, blue: 118/255)

    /// Mindfulness / sleep surface — purple register (PRISM canon).  #A78BFA
    nonisolated(unsafe) static var mindfulnessAccent: Color = Color(red: 167/255, green: 139/255, blue: 250/255)
}
