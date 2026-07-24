import SwiftUI

enum PrismStudioMode: String, CaseIterable, Identifiable {
    case image, video, edit
    var id: String { rawValue }
    var label: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        case .edit:  return "Edit"
        }
    }
    /// Only Image is backed by a real generation path today.
    var isImplemented: Bool { self == .image }
}

struct ImageGenerationView: View {
    @Bindable var env: ShellEnvironment
    @State private var mode: PrismStudioMode = .image
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var aspectRatio: ImageAspectRatio = .square
    @State private var style: ImageStylePreset = .cortexTech
    @State private var quality: ImageQuality = .high
    @State private var statusMessage = "Ready · network connection required"
    @State private var isGenerating = false
    @State private var lastError: String?
    @State private var activeJobID: UUID?

    /// Tracks the live ImageHistoryStore job when one is in flight, so the
    /// visible status line follows real Preparing → Generating → terminal
    /// transitions instead of jumping straight from start to end text.
    private var liveStatusText: String {
        if let id = activeJobID, let job = env.imageHistory.jobs.first(where: { $0.id == id }) {
            switch job.status {
            case .queued, .generating:
                if let progress = job.progressDetail, !progress.isEmpty {
                    return "\(job.status.displayLabel)… \(progress)"
                }
                return job.status.displayLabel + "…"
            default:
                return statusMessage
            }
        }
        return statusMessage
    }

    private let presets: [ImagePreset] = [
        ImagePreset(id: "tech", label: "Tech HUD", style: .cortexTech),
        ImagePreset(id: "blueprint", label: "Blueprint", style: .nodeBlueprint),
        ImagePreset(id: "exec", label: "Executive", style: .executiveDark),
        ImagePreset(id: "glass", label: "Glass", style: .minimalGlass),
        ImagePreset(id: "cortex_brand", label: "CORTEX Sheet", style: .cortexBrandSheet),
        ImagePreset(id: "s0", label: "Signal Zero", style: .signalZeroBlue),
        ImagePreset(id: "jericho", label: "Jericho", style: .jerichoRed),
        ImagePreset(id: "god_mode", label: "God Mode", style: .godModeHUD),
        ImagePreset(id: "babies", label: "Babies", style: .babiesChibi),
        ImagePreset(id: "sovereign", label: "Sovereign", style: .sovereignGold),
        ImagePreset(id: "aurion", label: "Aurion", style: .aurionGoldRed),
        ImagePreset(id: "pricing", label: "Pricing", style: .pricingHero),
        ImagePreset(id: "vehicle", label: "Vehicle UI", style: .vehicleCommand),
        ImagePreset(id: "atlas", label: "Atlas", style: .atlasOps),
    ]

    private let marketingCampaigns = CortexMarketingImageCanon.campaigns

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
                        Text("Compose · generate · save to Photos")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textSecondary)
                    }
                    Spacer()
                }

                ShellStatusBadge(
                    text: lastError != nil ? "Error · \(lastError!)" : "CORTEX MARKETING · God Mode presets loaded",
                    palette: palette,
                    tone: lastError != nil ? .warning : .neutral
                )

                modeAndReferenceRow(palette: palette)

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

                marketingCampaignStrip(palette: palette)

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
                        Text(mode.isImplemented ? (isGenerating ? "GENERATING…" : "GENERATE") : "COMING SOON")
                            .font(palette.captionFont)
                            .tracking(2)
                    }
                    .foregroundColor(palette.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isGenerating ? palette.accent.opacity(0.6) : (mode.isImplemented ? palette.accent : palette.textSecondary.opacity(0.35)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ShellPressableButtonStyle())
                .disabled(!mode.isImplemented || isGenerating || prompt.isEmpty)

                Text(liveStatusText)
                    .font(palette.captionFont)
                    .foregroundColor(lastError != nil ? .red.opacity(0.8) : palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                gallery(palette: palette)
                history(palette: palette)

                ShellAuditStrip(
                    palette: palette,
                    line: "Audit · CORTEX Image Service · Live network via authenticated CORTEX session · No API key on device"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 180)
        }
        .background(Color.black)
    }

    private func runGenerate() async {
        guard mode.isImplemented, !isGenerating, !prompt.isEmpty else { return }
        isGenerating = true
        lastError = nil
        env.orbState = .thinking
        statusMessage = ImageJob.Status.queued.displayLabel + "…"

        let jobID = UUID()
        activeJobID = jobID

        let job = await env.imageHistory.generate(
            id: jobID,
            prompt: prompt,
            negativePrompt: negativePrompt,
            aspectRatio: aspectRatio,
            style: style,
            quality: quality
        )

        isGenerating = false

        switch job.status {
        case .completed:
            statusMessage = "Completed · \(style.rawValue) · \(aspectRatio.rawValue)"
            env.orbState = .success
            env.showToast("Image saved", detail: "Saved to Photos", tone: .success)
        case .blocked:
            lastError = job.errorMessage ?? "Offline"
            statusMessage = "Offline · \(lastError!)"
            env.orbState = .idle
            env.showToast("Offline", detail: lastError!, tone: .warning)
        case .failed:
            lastError = job.errorMessage ?? "Generation failed"
            statusMessage = "Failed · \(lastError!)"
            env.orbState = .idle
            env.showToast("Failed", detail: lastError!, tone: .warning)
        case .queued, .generating:
            // generate() only returns once the job reaches a terminal state; this
            // branch exists only so the switch is exhaustive without a default.
            statusMessage = job.status.displayLabel + "…"
        }

        try? await Task.sleep(for: .milliseconds(1200))
        env.orbState = .idle
    }

    private func modeAndReferenceRow(palette: ShellThemePalette) -> some View {
        HStack(spacing: 8) {
            ForEach(PrismStudioMode.allCases) { m in
                Button {
                    guard m.isImplemented || mode != m else { return }
                    mode = m
                } label: {
                    VStack(spacing: 2) {
                        Text(m.label)
                            .font(.system(size: 11, weight: .semibold))
                        if !m.isImplemented {
                            Text("Coming Soon")
                                .font(.system(size: 8, weight: .medium))
                        }
                    }
                    .foregroundColor(mode == m ? palette.background : (m.isImplemented ? palette.textPrimary : palette.textSecondary.opacity(0.5)))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(mode == m ? palette.accent : palette.backgroundElevated)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "photo.badge.plus")
                Text("Coming Soon").font(.system(size: 7))
            }
            .foregroundColor(palette.textSecondary.opacity(0.4))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(palette.backgroundElevated.opacity(0.5))
            .clipShape(Capsule())
            .accessibilityLabel("Reference image — coming soon")
        }
    }

    private func marketingCampaignStrip(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CORTEX MARKETING · ONE TAP")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(palette.accent)
                .tracking(1.2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(marketingCampaigns) { campaign in
                        Button {
                            prompt = campaign.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                            negativePrompt = campaign.negativePrompt
                            aspectRatio = campaign.aspectRatio
                            style = campaign.style
                            quality = .high
                        } label: {
                            Text(campaign.shortLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(palette.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.accent.opacity(0.45), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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
                            Text("\(job.status.displayLabel.uppercased()) · \(job.aspectRatio.rawValue) · \(job.style.rawValue)")
                                .font(.system(size: 9))
                                .foregroundColor(job.status == .failed || job.status == .blocked ? .red.opacity(0.8) : palette.textSecondary)
                            if let msg = job.errorMessage {
                                Text(msg)
                                    .font(.system(size: 9))
                                    .foregroundColor(.red.opacity(0.7))
                                    .lineLimit(2)
                            }
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
    var footerNote: String = "Sent to CORTEX Intelligence · Requires network · No API key on device"

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
