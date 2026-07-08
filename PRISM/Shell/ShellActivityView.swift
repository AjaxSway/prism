import SwiftUI

struct ShellActivityView: View {
    @Bindable var env: ShellEnvironment
    @State private var selected: ShellActivityEvent?

    var body: some View {
        let palette = env.palette

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                activityHeader(palette: palette)

                ShellStatusBadge(
                    text: activityStatusBadge,
                    palette: palette,
                    tone: .warning
                )
                .padding(.horizontal, 20)

                if env.activityStore.events.isEmpty {
                    if env.config.appKind == .prism {
                        PrismLivingEmptyState(
                            palette: palette,
                            title: "No Activity Yet",
                            message: "Draft actions, refraction, and approvals appear here as you work.",
                            accent: palette.accent
                        )
                        .padding(.horizontal, 20)
                    } else {
                        ShellEmptyState(
                            palette: palette,
                            title: "No Activity Yet",
                            message: env.config.appKind == .prism
                                ? "Draft actions, refraction, and approvals appear here as you work."
                                : "Mock timeline events appear as you navigate the shell. No live telemetry.",
                            icon: "clock"
                        )
                    }
                } else {
                    ForEach(Array(env.activityStore.events.enumerated()), id: \.element.id) { index, event in
                        Button {
                            selected = event
                        } label: {
                            ShellGlassPanel(
                                palette: palette,
                                livingBorder: env.config.appKind == .prism,
                                livingSecondary: env.config.refractionPink
                            ) {
                                HStack(alignment: .top, spacing: 10) {
                                    roleAccentDot(palette: palette)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(palette.bodyFont.weight(.semibold))
                                            .foregroundColor(palette.textPrimary)
                                        Text(event.detail)
                                            .font(palette.captionFont)
                                            .foregroundColor(palette.textSecondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(event.timeLabel)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(palette.textSecondary)
                                        Text(eventKindLabel(for: event))
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(palette.warning)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .prismStaggerAppear(index: index, accent: palette.accent)
                    }
                }

                ShellAuditStrip(
                    palette: palette,
                    line: activityAuditLine,
                    accentTint: env.config.appKind == .prism ? palette.accent : nil
                )
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 180)
        }
        .background(ShellScreenBackground(palette: palette, appKind: env.config.appKind == .prism ? .prism : nil))
        .sheet(item: $selected) { event in
            activityDetail(event, palette: palette)
        }
    }

    @ViewBuilder
    private func activityHeader(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ShellMetallicTitle(text: "Activity", size: 22, accent: palette.accent)
            Text(activitySubtitle)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var activityStatusBadge: String {
        switch env.config.appKind {
        case .prism: return "Local audit · Draft-only · Not connected"
        case .cortexNode: return "Mock timeline · Shell preview · Local only"
        case .jericho: return "Mock timeline · Shell preview · Local only"
        }
    }

    private var activityAuditLine: String {
        switch env.config.appKind {
        case .prism: return "Append-only local audit · No live publish · Export via Share"
        default: return "Activity log is local mock data · Connect later for live audit sync"
        }
    }

    private func eventKindLabel(for event: ShellActivityEvent) -> String {
        if env.config.appKind == .prism { return "LOCAL" }
        return "MOCK"
    }

    private var activitySubtitle: String {
        switch env.config.appKind {
        case .cortexNode: return "Network events · Offline preview · Not connected"
        case .jericho: return "Trust audit trail · Advisory · Shell preview"
        case .prism: return "Draft signals · Refraction log · No live publishing"
        }
    }

    @ViewBuilder
    private func roleAccentDot(palette: ShellThemePalette) -> some View {
        if env.config.appKind == .prism {
            PrismLivingStatusDot(color: palette.accent, active: true, size: 5)
                .frame(width: 3, height: 36)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(palette.accent.opacity(0.85))
                .frame(width: 3, height: 36)
        }
    }

    private func activityDetail(_ event: ShellActivityEvent, palette: ShellThemePalette) -> some View {
        NavigationStack {
            ZStack {
                ShellScreenBackground(palette: palette, appKind: env.config.appKind == .prism ? .prism : nil)
                ShellGlassPanel(palette: palette) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(event.title)
                            .font(palette.titleFont)
                            .foregroundColor(palette.textPrimary)
                        Text(event.timeLabel)
                            .font(palette.captionFont)
                            .foregroundColor(palette.textSecondary)
                        Text(event.detail)
                            .font(palette.bodyFont)
                            .foregroundColor(palette.textPrimary)
                        ShellStatusBadge(
                            text: env.config.appKind == .prism ? "Local audit event" : "Mock event · Shell preview",
                            palette: palette
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
