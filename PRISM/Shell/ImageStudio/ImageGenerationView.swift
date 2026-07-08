import SwiftUI

struct ImageGenerationView: View {
    @Bindable var env: ShellEnvironment
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var aspectRatio: ImageAspectRatio = .square
    @State private var style: ImageStylePreset = .cortexTech
    @State private var quality: ImageQuality = .high
    @State private var statusMessage = "Local draft generator · approval required"
    @State private var isGenerating = false
    @State private var lastError: String?

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

                ShellStatusBadge(
                    text: lastError != nil ? "Error · \(lastError!)" : "Draft-only · Not connected",
                    palette: palette,
                    tone: lastError != nil ? .warning : .neutral
                )

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
                    quality: $quality,
                    presets: presets
                )

                Button {
                    Task { await runGenerate() }
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating { ProgressView().tint(palette.background) }
                        Text(isGenerating ? "GENERATING…" : "GENERATE")
                            .font(palette.captionFont)
                            .tracking(2)
                    }
                    .foregroundColor(palette.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isGenerating ? palette.accent.opacity(0.6) : palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ShellPressableButtonStyle())
                .disabled(isGenerating || prompt.isEmpty)

                Text(statusMessage)
                    .font(palette.captionFont)
                    .foregroundColor(lastError != nil ? .red.opacity(0.8) : palette.textSecondary)
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
            .padding(.bottom, 180)
        }
        .background(Color.black)
    }

    private func runGenerate() async {
        guard !isGenerating, !prompt.isEmpty else { return }
        isGenerating = true
        lastError = nil
        env.orbState = .thinking
        statusMessage = "Sending to CORTEX Intelligence…"

        let job = await env.imageHistory.generate(
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            quality: quality
        )

        isGenerating = false

        if job.status == .completed {
            statusMessage = "Generated · \(style.rawValue) · \(aspectRatio.rawValue)"
            env.orbState = .success
            env.showToast("Image ready", detail: "Tap gallery to view", tone: .success)
        } else {
            lastError = "Generation failed — check connection"
            statusMessage = lastError!
            env.orbState = .idle
            env.showToast("Generation failed", detail: "Check your connection and try again", tone: .warning)
        }

        try? await Task.sleep(for: .milliseconds(1200))
        env.orbState = .idle
    }

    private func gallery(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gallery")
                    .font(palette.bodyFont.weight(.semibold))
                    .foregroundColor(palette.textPrimary)
                if env.imageHistory.results.isEmpty {
                    Text("Generated images appear here.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(env.imageHistory.results.prefix(9)) { result in
                            Group {
                                if let url = result.imageURL {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable().scaledToFill()
                                        case .failure:
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.red.opacity(0.6))
                                        default:
                                            ProgressView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo").foregroundColor(palette.textSecondary.opacity(0.4))
                                }
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .background(palette.background.clipShape(RoundedRectangle(cornerRadius: 8)))
                            .onTapGesture { env.imageHistory.selectedResult = result }
                        }
                    }
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
    @Binding var quality: ImageQuality
    let presets: [ImagePreset]
    var footerNote: String = "Local preset · Quality saved in draft metadata · No cloud keys"

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

                Text("Quality")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
                Picker("Quality", selection: $quality) {
                    ForEach(ImageQuality.allCases) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .pickerStyle(.segmented)
                Text(footerNote)
                    .font(.system(size: 9))
                    .foregroundColor(palette.textSecondary.opacity(0.7))

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
