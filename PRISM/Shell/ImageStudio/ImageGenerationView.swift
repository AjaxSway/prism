import SwiftUI

struct ImageGenerationView: View {
    @Bindable var env: ShellEnvironment
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var aspectRatio: ImageAspectRatio = .square
    @State private var style: ImageStylePreset = .cortexTech
    @State private var statusMessage = "Generate disabled · Offline preview · Connect later · \(ImageGenerationEndpoint.futurePath)"

    private let presets: [ImagePreset] = [
        ImagePreset(id: "tech", label: "Tech HUD", style: .cortexTech),
        ImagePreset(id: "blueprint", label: "Blueprint", style: .nodeBlueprint),
        ImagePreset(id: "exec", label: "Executive", style: .executiveDark),
        ImagePreset(id: "glass", label: "Glass", style: .minimalGlass),
    ]

    var body: some View {
        let palette = env.palette

        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [palette.accent.opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: 24))
                            .frame(width: 42, height: 42)
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(palette.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IMAGE STUDIO")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(LinearGradient(colors: [.white, palette.accent], startPoint: .leading, endPoint: .trailing))
                        Text("Compose · preview · connect later")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textSecondary)
                    }
                    Spacer()
                }

                ShellStatusBadge(text: "Offline · \(ImageGenerationEndpoint.futurePath)", palette: palette, tone: .warning)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(presets) { preset in
                            ShellGlowToolCard(
                                title: preset.label,
                                subtitle: style == preset.style ? "Selected" : "Preset",
                                icon: "photo.artframe",
                                glow: style == preset.style ? palette.accent : palette.textSecondary,
                                palette: palette
                            ) { style = preset.style }
                            .frame(width: 148)
                        }
                    }
                }

                ImagePromptComposer(
                    palette: palette,
                    prompt: $prompt,
                    negativePrompt: $negativePrompt,
                    aspectRatio: $aspectRatio,
                    style: $style,
                    presets: presets
                )

                Button {} label: {
                    Text("GENERATE (DISABLED)")
                        .font(palette.captionFont)
                        .tracking(2)
                        .foregroundColor(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(palette.glassStroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(true)

                Text(statusMessage)
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Safety: No provider keys in app. Generation remains disconnected until backend wiring.")
                    .font(.system(size: 10))
                    .foregroundColor(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                gallery(palette: palette)
                history(palette: palette)

                ShellAuditStrip(
                    palette: palette,
                    line: "Audit · Prompt timestamp local · Model: placeholder · No network"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(Color.black)
    }

    private func gallery(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gallery")
                    .font(palette.bodyFont.weight(.semibold))
                    .foregroundColor(palette.textPrimary)
                if env.imageHistory.results.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(palette.background)
                                .frame(height: 72)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(palette.textSecondary.opacity(0.4))
                                )
                        }
                    }
                    Text("No generated images · Shell preview placeholders")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                } else {
                    Text("Results appear here after future wiring.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
    }

    private func history(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text("History")
                    .font(palette.bodyFont.weight(.semibold))
                    .foregroundColor(palette.textPrimary)
                if env.imageHistory.jobs.isEmpty {
                    Text("No staged jobs.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                } else {
                    ForEach(env.imageHistory.jobs.prefix(5)) { job in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.prompt)
                                .font(palette.captionFont)
                                .foregroundColor(palette.textPrimary)
                                .lineLimit(1)
                            Text("\(job.status.rawValue.uppercased()) · \(job.aspectRatio.rawValue) · \(job.style.rawValue)")
                                .font(.system(size: 9))
                                .foregroundColor(palette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

struct ImagePromptComposer: View {
    let palette: ShellThemePalette
    @Binding var prompt: String
    @Binding var negativePrompt: String
    @Binding var aspectRatio: ImageAspectRatio
    @Binding var style: ImageStylePreset
    let presets: [ImagePreset]

    var body: some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Prompt")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                TextField("Describe an image…", text: $prompt, axis: .vertical)
                    .font(palette.bodyFont)
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(2...5)

                Text("Negative prompt (optional)")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                TextField("Exclude elements…", text: $negativePrompt)
                    .font(palette.bodyFont)
                    .foregroundColor(palette.textPrimary)

                Text("Aspect ratio")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                Picker("Aspect", selection: $aspectRatio) {
                    ForEach(ImageAspectRatio.allCases) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                .pickerStyle(.segmented)

                Text("Style")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                Picker("Style", selection: $style) {
                    ForEach(ImageStylePreset.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets) { preset in
                            Button { style = preset.style } label: {
                                Text(preset.label)
                                    .font(palette.captionFont)
                                    .foregroundColor(style == preset.style ? palette.background : palette.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(style == preset.style ? palette.accent : palette.backgroundElevated)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
