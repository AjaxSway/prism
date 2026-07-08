import SwiftUI
import UIKit

// MARK: - Toast · Connect sheet · Briefing · Haptics · Press animations

enum ShellToastTone: Sendable {
    case info, success, warning, action

    var icon: String {
        switch self {
        case .info: return "sparkles"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .action: return "bolt.fill"
        }
    }

    var accent: Color {
        switch self {
        case .info: return Color(red: 0.35, green: 0.75, blue: 1)
        case .success: return Color(red: 0.2, green: 0.85, blue: 0.55)
        case .warning: return Color(red: 0.95, green: 0.65, blue: 0.2)
        case .action: return Color(red: 0.925, green: 0.286, blue: 0.600)
        }
    }
}

struct ShellToast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let tone: ShellToastTone
}

struct ShellConnectSheetPayload: Identifiable, Equatable {
    let id = UUID()
    let feature: String
    let detail: String
    let steps: [String]
}

struct ShellBriefingPayload: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let bullets: [String]
    let accentLabel: String
}

// MARK: - Press style

struct ShellPressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct ShellShimmerModifier: ViewModifier {
    let accent: Color
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, accent.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.45)
                    .offset(x: geo.size.width * phase)
                    .blendMode(.screen)
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shellShimmer(accent: Color) -> some View {
        modifier(ShellShimmerModifier(accent: accent))
    }

    func shellInteractionOverlay(env: ShellEnvironment) -> some View {
        modifier(ShellInteractionOverlayModifier(env: env))
    }
}

// MARK: - Overlay (toast + sheets)

private struct ShellInteractionOverlayModifier: ViewModifier {
    @Bindable var env: ShellEnvironment

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = env.toast {
                    ShellToastBanner(toast: toast, palette: env.palette)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(50)
                }
            }
            .sheet(item: $env.connectSheet) { payload in
                ShellConnectLaterSheet(payload: payload, palette: env.palette, accent: env.palette.accent)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $env.activeBriefing) { payload in
                ShellBriefingSheet(payload: payload, palette: env.palette, primary: env.palette.accent)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $env.shareSheet) { payload in
                ShellShareSheet(payload: payload)
            }
            .sheet(isPresented: $env.showSubscriptionPlans) {
                ShellSubscriptionPlansSheet(env: env)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: env.toast)
    }
}

private struct ShellToastBanner: View {
    let toast: ShellToast
    let palette: ShellThemePalette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.tone.accent)
                .shadow(color: toast.tone.accent.opacity(0.45), radius: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                Text(toast.detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(toast.tone.accent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: toast.tone.accent.opacity(0.2), radius: 12, y: 4)
        )
    }
}

struct ShellConnectLaterSheet: View {
    let payload: ShellConnectSheetPayload
    let palette: ShellThemePalette
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Requires setup")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(payload.feature)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(accent)
                    }
                    Spacer()
                }

                Text(payload.detail)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("WHEN BRAIN CONNECTS")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(palette.textSecondary)
                    ForEach(Array(payload.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(accent))
                            Text(step)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(palette.textPrimary)
                        }
                    }
                }

                ShellStatusBadge(text: "Platform preview · No fake live state", palette: palette, tone: .warning)

                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ShellPressableButtonStyle())
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

struct ShellBriefingSheet: View {
    let payload: ShellBriefingPayload
    let palette: ShellThemePalette
    let primary: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [primary.opacity(0.12), Color.black],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(payload.accentLabel.uppercased())
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(primary)
                        .tracking(2)
                    Text(payload.title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(payload.subtitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(palette.textSecondary)

                    ForEach(payload.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(primary).frame(width: 6, height: 6).padding(.top, 6)
                            Text(bullet)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(palette.textPrimary)
                        }
                    }

                    ShellStatusBadge(text: "Mock briefing · Brain connects for live coaching", palette: palette)

                    Button {
                        dismiss()
                    } label: {
                        Text("Close briefing")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ShellPressableButtonStyle())
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mock refraction preview animation

struct ShellRefractionPreviewOverlay: View {
    let channels: [String]
    let accent: Color
    let secondary: Color
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.72).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("REFRACTION PREVIEW")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(LinearGradient(colors: [accent, secondary], startPoint: .leading, endPoint: .trailing))
                    ShellRefractionBeamDeck(violet: accent, pink: secondary, cyan: .cyan, orbState: .executing, onOrbTap: {})
                        .frame(height: 120)
                    VStack(spacing: 8) {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(channels, id: \.self) { ch in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(accent)
                                        Text(ch).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                        Spacer()
                                        Text("Draft staged")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.45))
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .frame(maxHeight: 160)
                    }
                    Text("Saved to Draft Queue · Approval required before publish")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(24)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Share · Subscription

struct ShellShareSheet: UIViewControllerRepresentable {
    let payload: ShellSharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [payload.text]
        if let name = payload.imageName, let image = UIImage(named: name) {
            items.append(image)
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShellSubscriptionPlansSheet: View {
    @Bindable var env: ShellEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let palette = env.palette
        let config = env.config
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Plans & Pricing")
                    .font(palette.titleFont)
                    .foregroundColor(palette.textPrimary)
                Text("Subscriptions activate when App Store products are configured. All draft features work on Free today.")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)

                planCard(
                    title: "Free",
                    price: "Included",
                    bullets: ["Draft composer", "Local refraction preview", "Image preset studio", "Approval gate"],
                    palette: palette,
                    accent: palette.textSecondary
                )
                planCard(
                    title: "Pro",
                    price: config.monthlyPriceDisplay,
                    bullets: ["Unlimited channel packs", "Campaign calendar", "Proof asset library", "Priority export (when live)"],
                    palette: palette,
                    accent: palette.accent
                )

                Text("Product ID: com.cortexnode.prism.pro.monthly")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(palette.textSecondary)

                Button {
                    dismiss()
                    env.showToast("Subscribe", detail: "Available after App Store Connect setup", tone: .info)
                } label: {
                    Text("SUBSCRIBE — APP STORE SETUP PENDING")
                        .font(palette.captionFont)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ShellPressableButtonStyle())

                Button {
                    dismiss()
                    env.showToast("Restore", detail: ShellStoreKitError.notConfigured.errorDescription ?? "Not configured", tone: .warning)
                } label: {
                    Text("RESTORE PURCHASES")
                        .font(palette.captionFont)
                        .foregroundColor(palette.accent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func planCard(title: String, price: String, bullets: [String], palette: ShellThemePalette, accent: Color) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(palette.bodyFont.weight(.bold)).foregroundColor(palette.textPrimary)
                    Spacer()
                    Text(price).font(.system(size: 12, weight: .black, design: .monospaced)).foregroundColor(accent)
                }
                ForEach(bullets, id: \.self) { line in
                    Label(line, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
    }
}
