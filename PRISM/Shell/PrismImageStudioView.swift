import SwiftUI

// RETIRED — mock image generator, not reachable from any production build.
// PremiumShellRouter.swift routes PRISM's Studio tab to the real
// ImageGenerationView (ImageStudio/ImageGenerationView.swift) instead, which
// calls the authenticated CORTEXNODE backend (POST /generate-image) via
// DALLEImageGenerationService. PrismMockImageResult/presetForPrompt() below
// return bundled preset images regardless of the prompt — never wire this
// view back into a production tab. Kept for historical reference only.
struct PrismImageStudioView: View {
    @Bindable var env: ShellEnvironment
    @State private var prompt = ""
    @State private var aspectRatio: ImageAspectRatio = .square
    @State private var selectedPreset: PrismVisionPreset = .cortexPoster
    @State private var referencePreset: PrismVisionPreset = .cortexPoster
    @State private var mediaMode: PrismStudioMediaMode = .image
    @State private var selectedStyle: PrismImageStyle = .cinematic
    @State private var selectedResult: PrismMockImageResult?
    @State private var mockResults: [PrismMockImageResult] = []
    @State private var isGenerating = false
    @State private var generateProgress: CGFloat = 0
    @FocusState private var promptFocused: Bool

    private var violet: Color { env.config.refractionAccent ?? Color(red: 0.545, green: 0.361, blue: 0.965) }
    private var pink: Color { env.config.refractionPink ?? Color(red: 0.925, green: 0.286, blue: 0.600) }

    var body: some View {
        let palette = env.palette

        ZStack {
            Color.black.ignoresSafeArea()
            ShellAmbientBackground(palette: palette, accentOverride: violet, intensity: 0.35, theme: env.theme, appKind: .prism)

            VStack(spacing: 0) {
                studioTopBar(palette: palette)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        canvasArea
                            .padding(.horizontal, 12)
                            .padding(.top, 8)

                        if !mockResults.isEmpty {
                            recentStrip(palette: palette)
                                .padding(.top, 10)
                        }

                        studioControls(palette: palette)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }
                }

                chatComposer(palette: palette)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                auditFooter(palette: palette)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .safeAreaPadding(.bottom, 148)
        }
        .onAppear { reloadGalleryFromStore() }
    }

    // MARK: - Top bar

    private func studioTopBar(palette: ShellThemePalette) -> some View {
        HStack(spacing: 10) {
            Text("Create")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(palette.textPrimary)
                .accessibilityIdentifier("prism-studio-title")
            Text("· draft-only")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(palette.textSecondary)
            Spacer()
            if activeImageName != nil {
                Button {
                    shareActiveImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(violet)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            let height = max(geo.size.height, 280)
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(white: 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay {
                        PrismLivingBorder(accent: violet, secondary: pink, cornerRadius: 20, lineWidth: 1)
                    }

                PrismStudioCanvasGlow(violet: violet, pink: pink, active: isGenerating || prompt.isEmpty)

                if isGenerating {
                    generatingOverlay
                } else if let name = activeImageName {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    emptyCanvas
                }
            }
            .frame(width: geo.size.width, height: height)
        }
        .frame(minHeight: 320)
    }

    private var emptyCanvas: some View {
        ZStack {
            Image("PRISMIntroHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.12)
                .blur(radius: 2)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 16) {
                ZStack {
                    PrismPulseRing(color: violet, secondary: pink, diameter: 92, lineWidth: 1.1, speed: 1.2)
                    ShellPrismCoreOrb(violet: violet, pink: pink, size: 72, intensity: 1.0, orbState: env.orbState)
                }
                Text("Describe an image below")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                Text("Saved locally · no cloud keys")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.32))
            }
            .padding(24)
        }
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
            VStack(spacing: 16) {
                ShellPrismCoreOrb(violet: violet, pink: pink, size: 64, intensity: 1.1, orbState: .executing)
                Text("Creating draft…")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(colors: [violet, pink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * generateProgress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 48)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Mode · reference · style

    private func studioControls(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(PrismStudioMediaMode.allCases) { mode in
                    modeChip(mode, palette: palette)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                referenceSlot(palette: palette)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reference")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textSecondary)
                    Text("Bundled preset · on device")
                        .font(.system(size: 9))
                        .foregroundColor(palette.textSecondary.opacity(0.85))
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(PrismImageStyle.allCases) { style in
                        styleChip(style, palette: palette)
                    }
                }
            }
        }
    }

    private func modeChip(_ mode: PrismStudioMediaMode, palette: ShellThemePalette) -> some View {
        Button {
            mediaMode = mode
            env.impact(.light)
        } label: {
            Text(mode.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(mediaMode == mode ? .black : palette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(mediaMode == mode ? violet : Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("prism-studio-mode-\(mode.rawValue)")
    }

    private func styleChip(_ style: PrismImageStyle, palette: ShellThemePalette) -> some View {
        Button {
            selectedStyle = style
            env.impact(.light)
        } label: {
            Text(style.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(selectedStyle == style ? .black : palette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(selectedStyle == style ? pink : Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func referenceSlot(palette: ShellThemePalette) -> some View {
        Menu {
            ForEach(PrismVisionPreset.allCases) { preset in
                Button(preset.label) {
                    referencePreset = preset
                    selectedPreset = preset
                    env.impact(.light)
                }
            }
        } label: {
            Group {
                if let img = referencePreset.assetImageName {
                    Image(img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(referencePreset.gradient)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(violet.opacity(0.55), lineWidth: 1)
            )
        }
        .accessibilityIdentifier("prism-studio-reference")
    }

    private func auditFooter(palette: ShellThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Draft-only · Approval required · Not connected · Saved on device")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(palette.textSecondary)
            Text("Local preset generator · No cloud keys · Share exports drafts you approve")
                .font(.system(size: 8))
                .foregroundColor(palette.textSecondary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recent strip

    private func recentStrip(palette: ShellThemePalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mockResults.prefix(8)) { result in
                    Button {
                        selectedResult = result
                        if let preset = PrismVisionPreset.allCases.first(where: { $0.label == result.preset.label }) {
                            selectedPreset = preset
                        }
                    } label: {
                        Group {
                            if let img = result.preset.assetImageName {
                                Image(img).resizable().scaledToFill()
                            } else {
                                Rectangle().fill(result.preset.gradient)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedResult?.id == result.id ? violet : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - ChatGPT-style composer

    private func chatComposer(palette: ShellThemePalette) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                aspectChip("1:1", ratio: .square, palette: palette)
                aspectChip("16:9", ratio: .landscape, palette: palette)
                aspectChip("9:16", ratio: .portrait, palette: palette)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Describe an image…", text: $prompt, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 16))
                    .foregroundColor(palette.textPrimary)
                    .accessibilityIdentifier("prism-studio-prompt")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(white: 0.11))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(promptFocused ? 0.18 : 0.08), lineWidth: 1)
                            )
                    )
                    .focused($promptFocused)

                Button {
                    Task { await runMockGenerate() }
                } label: {
                    Group {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                canGenerate
                                    ? LinearGradient(colors: [violet, pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                            )
                    )
                }
                .buttonStyle(ShellPressableButtonStyle(scale: 0.92))
                .disabled(!canGenerate || isGenerating)
                .accessibilityIdentifier("prism-generate-draft")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func aspectChip(_ label: String, ratio: ImageAspectRatio, palette: ShellThemePalette) -> some View {
        Button {
            aspectRatio = ratio
            env.impact(.light)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(aspectRatio == ratio ? .black : palette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(aspectRatio == ratio ? violet : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }

    private var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedResult != nil
    }

    private var activeImageName: String? {
        if let selected = selectedResult { return selected.preset.assetImageName }
        return selectedPreset.assetImageName
    }

    private func shareActiveImage() {
        let text = selectedResult?.prompt ?? prompt
        let image = activeImageName
        env.presentShare(text: text.isEmpty ? "PRISM image draft" : text, imageName: image)
    }

    // MARK: - Data

    private func reloadGalleryFromStore() {
        mockResults = env.draftStore.imageAssets.map { asset in
            let preset = PrismVisionPreset.allCases.first(where: { $0.label == asset.presetLabel }) ?? .cortexPoster
            return PrismMockImageResult(id: asset.id.uuidString, prompt: asset.prompt, preset: preset, style: .cinematic)
        }
        if selectedResult == nil, let first = mockResults.first {
            selectedResult = first
        }
    }

    private func runMockGenerate() async {
        guard !isGenerating else { return }
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isGenerating = true
        promptFocused = false
        withAnimation(.none) { generateProgress = 0 }
        env.orbState = .thinking
        env.impact(.medium)
        withAnimation(.easeInOut(duration: 2.4)) { generateProgress = 1.0 }
        try? await Task.sleep(for: .milliseconds(2500))

        selectedPreset = presetForPrompt(trimmed)
        if referencePreset != selectedPreset { referencePreset = selectedPreset }
        addMockDraft(logDraft: false, style: selectedStyle, mode: mediaMode)

        withAnimation(.easeOut(duration: 0.25)) { generateProgress = 0 }
        isGenerating = false
        env.orbState = .success
        env.showToast("Image saved", detail: "Local draft · tap share to export", tone: .success)
        env.activityStore.append(title: "Image draft saved locally", detail: trimmed.prefix(80).description, kind: .command)
        try? await Task.sleep(for: .milliseconds(700))
        env.orbState = .idle
    }

    private func presetForPrompt(_ text: String) -> PrismVisionPreset {
        let lower = text.lowercased()
        if lower.contains("forge") { return .forgeCharacter }
        if lower.contains("aurion") || lower.contains("gold armor") { return .aurionGold }
        if lower.contains("b2tb") || lower.contains("pillar") || lower.contains("doctrine") { return .b2tbPillars }
        if lower.contains("map") || lower.contains("ecosystem") { return .ecosystemMap }
        if lower.contains("control") || lower.contains("dashboard") { return .controlCenter }
        if lower.contains("jericho") { return .jerichoSheet }
        if lower.contains("god mode") { return .godModeHUD }
        if lower.contains("signal zero") || lower.contains("execution layer") { return .signalZeroSheet }
        if lower.contains("baby") || lower.contains("babies") || lower.contains("chibi") { return .babiesRoster }
        if lower.contains("sovereign") { return .sovereignPoster }
        if lower.contains("pricing") || lower.contains("choose your cortex") { return .pricingUniverse }
        if lower.contains("atlas") { return .atlasOps }
        if lower.contains("brand sheet") || lower.contains("quick sheet") { return .cortexBrandSheet }
        return .cortexPoster
    }

    private func addMockDraft(logDraft: Bool = true, style: PrismImageStyle? = nil, mode: PrismStudioMediaMode? = nil) {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? selectedPreset.defaultPrompt
            : prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let appliedStyle = style ?? selectedStyle
        let appliedMode = mode ?? mediaMode
        let result = PrismMockImageResult(
            id: UUID().uuidString,
            prompt: "[\(appliedMode.label)/\(appliedStyle.label)] \(text)",
            preset: selectedPreset,
            style: appliedStyle
        )
        mockResults.insert(result, at: 0)
        selectedResult = result
        _ = env.draftStore.saveImageAsset(
            prompt: text,
            presetLabel: selectedPreset.label,
            assetImageName: selectedPreset.assetImageName
        )
        if logDraft {
            env.saveDraftPreview(module: "Image Studio", snippet: text)
        }
    }
}

enum PrismStudioMediaMode: String, CaseIterable, Identifiable {
    case image, video, edit
    var id: String { rawValue }
    var label: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        case .edit: return "Edit"
        }
    }
}

enum PrismImageStyle: String, CaseIterable, Identifiable {
    case cinematic, poster, doctrine, character, hud, raw
    var id: String { rawValue }
    var label: String {
        switch self {
        case .cinematic: return "Cinematic"
        case .poster: return "Poster"
        case .doctrine: return "B2TB Doctrine"
        case .character: return "Character"
        case .hud: return "HUD / Tech"
        case .raw: return "Raw"
        }
    }
}

enum PrismVisionPreset: String, CaseIterable, Identifiable {
    case cortexPoster, b2tbPillars, controlCenter, forgeCharacter, aurionGold, ecosystemMap
    case cortexBrandSheet, signalZeroSheet, jerichoSheet, godModeHUD
    case babiesRoster, sovereignPoster, pricingUniverse, atlasOps, s0Execution

    var id: String { rawValue }
    var label: String {
        switch self {
        case .cortexPoster: return "CORTEX Poster"
        case .b2tbPillars: return "B2TB Pillars"
        case .controlCenter: return "Control Center"
        case .forgeCharacter: return "FORGE Character"
        case .aurionGold: return "AURION Gold"
        case .ecosystemMap: return "Ecosystem Map"
        case .cortexBrandSheet: return "CORTEX Sheet"
        case .signalZeroSheet: return "Signal Zero"
        case .jerichoSheet: return "Jericho"
        case .godModeHUD: return "God Mode"
        case .babiesRoster: return "Babies Cards"
        case .sovereignPoster: return "Sovereign"
        case .pricingUniverse: return "Pricing"
        case .atlasOps: return "Atlas Ops"
        case .s0Execution: return "S0 Execution"
        }
    }
    var assetImageName: String? {
        switch self {
        case .cortexPoster: return "ShellPresetCortex"
        case .b2tbPillars: return "ShellPresetB2TB"
        case .controlCenter: return "ShellPresetControl"
        case .forgeCharacter: return "ShellPresetForge"
        case .aurionGold: return "ShellPresetAurion"
        case .ecosystemMap: return "ShellPresetEcosystem"
        case .cortexBrandSheet, .signalZeroSheet, .jerichoSheet, .godModeHUD,
             .babiesRoster, .sovereignPoster, .pricingUniverse, .atlasOps, .s0Execution:
            return nil
        }
    }
    var gradient: LinearGradient {
        switch self {
        case .cortexPoster, .cortexBrandSheet:
            return LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.95), Color(red: 0.05, green: 0.15, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .b2tbPillars:
            return LinearGradient(colors: [Color(red: 0.95, green: 0.45, blue: 0.1), Color(red: 0.55, green: 0.15, blue: 0.05)], startPoint: .top, endPoint: .bottom)
        case .controlCenter, .signalZeroSheet, .s0Execution:
            return LinearGradient(colors: [Color(red: 0.0, green: 0.75, blue: 0.95), Color.black], startPoint: .top, endPoint: .bottom)
        case .forgeCharacter:
            return LinearGradient(colors: [Color(white: 0.25), Color(red: 0.1, green: 0.5, blue: 0.9)], startPoint: .leading, endPoint: .bottomTrailing)
        case .aurionGold, .sovereignPoster:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.15), Color(red: 0.6, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ecosystemMap, .atlasOps:
            return LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.1, green: 0.3, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .jerichoSheet, .godModeHUD:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.12, blue: 0.18), Color.black], startPoint: .top, endPoint: .bottom)
        case .babiesRoster:
            return LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 0.95), Color(red: 0.1, green: 0.4, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pricingUniverse:
            return LinearGradient(colors: [Color(red: 0.15, green: 0.35, blue: 0.95), Color(red: 0.55, green: 0.2, blue: 0.85)], startPoint: .leading, endPoint: .trailing)
        }
    }
    var defaultPrompt: String {
        switch self {
        case .cortexPoster: return "CORTEX cinematic robot poster, cyan core glow, void black, premium HUD"
        case .b2tbPillars: return "Back to the Basics 12 pillars, gold orange nebula, doctrine wheel"
        case .controlCenter: return "CORTEX control center holographic dashboard, system map, telemetry"
        case .forgeCharacter: return "FORGE execution layer chibi robot, hammer, cyan glow, industrial forge"
        case .aurionGold: return "AURION legacy command intelligence, gold armor, red core, championship mode"
        case .ecosystemMap: return "CORTEXNODE ecosystem map five layers, neon lanes, command control"
        case .cortexBrandSheet:
            return CortexMarketingImageCanon.campaign(id: "cortex_brand_sheet")?.prompt
                ?? "CORTEX brand sheet metallic wordmark cyan glow quick sheet HUD"
        case .signalZeroSheet:
            return CortexMarketingImageCanon.campaign(id: "signal_zero_sheet")?.prompt
                ?? "SIGNAL ZERO brand sheet ice blue NO NOISE JUST TRUTH"
        case .jerichoSheet:
            return CortexMarketingImageCanon.campaign(id: "jericho_sheet")?.prompt
                ?? "JERICHO war-room crimson brand sheet"
        case .godModeHUD:
            return CortexMarketingImageCanon.campaign(id: "god_mode_blue")?.prompt
                ?? "CORTEX God Mode circular vault HUD cyan crown"
        case .babiesRoster:
            return CortexMarketingImageCanon.campaign(id: "babies_roster")?.prompt
                ?? "CORTEX Babies chibi character card grid"
        case .sovereignPoster:
            return CortexMarketingImageCanon.campaign(id: "sovereign_poster")?.prompt
                ?? "CORTEX SOVEREIGN cyber imperial gold poster"
        case .pricingUniverse:
            return CortexMarketingImageCanon.campaign(id: "pricing_universe")?.prompt
                ?? "CORTEX pricing universe plan cards"
        case .atlasOps:
            return CortexMarketingImageCanon.campaign(id: "atlas_ops")?.prompt
                ?? "ATLAS Operational Intelligence OS marketing"
        case .s0Execution:
            return CortexMarketingImageCanon.campaign(id: "s0_execution")?.prompt
                ?? "SIGNAL ZERO Execution Layer phone arc marketing"
        }
    }
}

struct PrismMockImageResult: Identifiable {
    let id: String
    let prompt: String
    let preset: PrismVisionPreset
    let style: PrismImageStyle
}
