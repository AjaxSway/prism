import SwiftUI

struct ShellActivityView: View {
    @Bindable var env: ShellEnvironment
    @State private var selected: ShellActivityEvent?

    var body: some View {
        let palette = env.palette

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text("Activity")
                    .font(palette.titleFont)
                    .foregroundColor(palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if env.activityStore.events.isEmpty {
                    ShellEmptyState(
                        palette: palette,
                        title: "No Activity Yet",
                        message: "Mock timeline events will appear here as you navigate the shell.",
                        icon: "clock"
                    )
                } else {
                    ForEach(env.activityStore.events) { event in
                        Button {
                            selected = event
                        } label: {
                            ShellGlassPanel(palette: palette) {
                                HStack(alignment: .top, spacing: 10) {
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
                                        Text(event.kind.rawValue.uppercased())
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(palette.accentSoft)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(ShellScreenBackground(palette: palette))
        .sheet(item: $selected) { event in
            activityDetail(event, palette: palette)
        }
    }

    private func activityDetail(_ event: ShellActivityEvent, palette: ShellThemePalette) -> some View {
        NavigationStack {
            ZStack {
                ShellScreenBackground(palette: palette)
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
                        ShellStatusBadge(text: "Mock event · Shell preview", palette: palette)
                    }
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selected = nil }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
