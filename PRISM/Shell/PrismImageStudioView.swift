import SwiftUI

/// PRISM Image Studio — ChatGPT-style canvas · Generate disabled until brain connects.
struct PrismImageStudioView: View {
    @Bindable var env: ShellEnvironment
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var aspectRatio: ImageAspectRatio = .square
    @State private var style: ImageStylePreset = .cortexTech
    @State private var selectedPreset: PrismVisionPreset = .cortexPoster
    @State private var selectedResult: PrismMockImageResult?
    @State private var mockResults: [PrismMockImageResult] = []
    @FocusState private var promptFocused: Bool

    private var violet: Color { env.config.refractionAccent ?? Color(red: 0.545, green: 0.361, blue: 0.965) }
    private var pink: Color { env.config.refractionPink ?? Color(red: 0.925, green: 0.286, blue: 0.600) }

    private let stylePresets: [ImagePreset] = [
        ImagePreset(id: "tech", label: "CORTEX Tech", style: .cortexTech),
        ImagePreset(id: "blueprint", label: "Node Blueprint", style: .nodeBlueprint),
        ImagePreset(id: "exec", label: "Executive Dark", style: .executiveDark),
        ImagePreset(id: "glass", label: "Minimal Glass", style: .minimalGlass),
    ]

    var body: some View {
        let palette = env.palette

        ZStack {
            Color.black.ignoresSafeArea()
            ShellAmbientBackground(palette: palette, accentOverride: violet, intensity: 0.5, theme: env.theme)
            if env.palette.usesScanlines {
                ShellScanlineOverlay(accent: violet, opacity: 0.035)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    studioHeader
                    ShellStatusBadge(text: "Image Studio · Generate disabled · \(ImageGenerationEndpoint.futurePath)", palette: palette, tone: .warning)

                    canvasArea
                    detailPanel(palette: palette)

                    ImagePromptComposer(
                        palette: palette,
                        prompt: $prompt,
                        negativePrompt: $negativePrompt,
                        aspectRatio: $aspectRatio,
                        style: $style,
                        presets: stylePresets
                    )

                    presetGrid
                    generateSection(palette: palette)
                    gallerySection(palette: palette)
                    historySection(palette: palette)
                    exportPlaceholders(palette: palette)

                    ShellAuditStrip(
                        palette: palette,
                        line: "Audit · Prompt timestamp local · Model: placeholder · \(ImageGenerationEndpoint.futurePath) · No network"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
    }

    private var studioHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("IMAGE STUDIO")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(LinearGradient(colors: [violet, pink], startPoint: .leading, endPoint: .trailing))
            Text("PRISM Canvas · CORTEX ecosystem visuals · B2TB doctrine art")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canvasArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [violet.opacity(0.4), pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                .frame(height: 240)

            if let selected = selectedResult, let img = selected.preset.assetImageName {
                Image(img).resizable().scaledToFill().frame(height: 240).clipped().overlay(ShellHUDBrackets(accent: violet))
            } else if let img = selectedPreset.assetImageName {
                Image(img).resizable().scaledToFill().frame(height: 240).clipped()
                    .overlay(LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom))
                    .overlay(ShellHUDBrackets(accent: violet))
            } else {
                VStack(spacing: 12) {
                    ShellPrismCoreOrb(violet: violet, pink: pink, size: 64, intensity: 0.85)
                    Text("Describe your vision · Pick a preset · Generate when brain connects")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func detailPanel(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SELECTED IMAGE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(violet.opacity(0.7))
                if let selected = selectedResult {
                    Text(selected.preset.label).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                    Text(selected.prompt).font(.system(size: 11)).foregroundColor(palette.textSecondary).lineLimit(3)
                    Text("Mock · Approval required · Draft-only")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(palette.warning)
                } else {
                    Text("Select a preset or mock result to inspect.")
                        .font(.system(size: 11))
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VISION PRESETS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PrismVisionPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        selectedResult = nil
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Group {
                                if let img = preset.assetImageName {
                                    Image(img).resizable().scaledToFill()
                                } else {
                                    RoundedRectangle(cornerRadius: 8).fill(preset.gradient)
                                }
                            }
                            .frame(height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedPreset == preset ? violet : Color.clear, lineWidth: 2))
                            Text(preset.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(selectedPreset == preset ? violet : .white.opacity(0.7))
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(selectedPreset == preset ? violet.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func generateSection(palette: ShellThemePalette) -> some View {
        VStack(spacing: 8) {
            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("GENERATE (DISABLED)")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white.opacity(0.35))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .disabled(true)

            Button { addMockDraft() } label: {
                Text("Preview Mock Protocol (offline)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(violet.opacity(0.8))
            }
            .buttonStyle(.plain)

            Text("Safety: No provider keys in app. Generation remains disconnected until backend wiring.")
                .font(.system(size: 10))
                .foregroundColor(palette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func gallerySection(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gallery")
                    .font(palette.bodyFont.weight(.semibold))
                    .foregroundColor(palette.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(mockResults) { result in
                        Button {
                            selectedResult = result
                        } label: {
                            Group {
                                if let img = result.preset.assetImageName {
                                    Image(img).resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(result.preset.gradient)
                                }
                            }
                            .frame(height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedResult?.id == result.id ? violet : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                    if mockResults.isEmpty {
                        ForEach(PrismVisionPreset.allCases.prefix(3)) { preset in
                            Group {
                                if let img = preset.assetImageName {
                                    Image(img).resizable().scaledToFill()
                                } else {
                                    RoundedRectangle(cornerRadius: 8).fill(preset.gradient)
                                }
                            }
                            .frame(height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .opacity(0.45)
                        }
                    }
                }
                Text(mockResults.isEmpty ? "No generated images · Shell preview placeholders" : "Tap mock results to inspect")
                    .font(palette.captionFont)
                    .foregroundColor(palette.textSecondary)
            }
        }
    }

    private func historySection(palette: ShellThemePalette) -> some View {
        ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                Text("History")
                    .font(palette.bodyFont.weight(.semibold))
                    .foregroundColor(palette.textPrimary)
                if mockResults.isEmpty && env.imageHistory.jobs.isEmpty {
                    Text("No staged jobs.")
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                } else {
                    ForEach(mockResults.prefix(5)) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.prompt).font(palette.captionFont).foregroundColor(palette.textPrimary).lineLimit(1)
                            Text("MOCK · \(aspectRatio.rawValue) · \(result.preset.label)")
                                .font(.system(size: 9))
                                .foregroundColor(palette.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func exportPlaceholders(palette: ShellThemePalette) -> some View {
        HStack(spacing: 10) {
            exportChip("Export", icon: "square.and.arrow.up", palette: palette)
            exportChip("Share", icon: "link", palette: palette)
            exportChip("Attach Proof", icon: "paperclip", palette: palette)
        }
    }

    private func exportChip(_ label: String, icon: String, palette: ShellThemePalette) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(palette.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Capsule().stroke(palette.glassStroke, lineWidth: 1))
    }

    private func addMockDraft() {
        let text = prompt.isEmpty ? selectedPreset.defaultPrompt : prompt
        let result = PrismMockImageResult(id: UUID().uuidString, prompt: text, preset: selectedPreset, style: .cinematic)
        mockResults.insert(result, at: 0)
        selectedResult = result
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
    var id: String { rawValue }
    var label: String {
        switch self {
        case .cortexPoster: return "CORTEX Poster"
        case .b2tbPillars: return "B2TB Pillars"
        case .controlCenter: return "Control Center"
        case .forgeCharacter: return "FORGE Character"
        case .aurionGold: return "AURION Gold"
        case .ecosystemMap: return "Ecosystem Map"
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
        }
    }
    var gradient: LinearGradient {
        switch self {
        case .cortexPoster:
            return LinearGradient(colors: [Color(red: 0.1, green: 0.4, blue: 0.95), Color(red: 0.05, green: 0.15, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .b2tbPillars:
            return LinearGradient(colors: [Color(red: 0.95, green: 0.45, blue: 0.1), Color(red: 0.55, green: 0.15, blue: 0.05)], startPoint: .top, endPoint: .bottom)
        case .controlCenter:
            return LinearGradient(colors: [Color(red: 0.0, green: 0.75, blue: 0.95), Color.black], startPoint: .top, endPoint: .bottom)
        case .forgeCharacter:
            return LinearGradient(colors: [Color(white: 0.25), Color(red: 0.1, green: 0.5, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
        case .aurionGold:
            return LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.15), Color(red: 0.6, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ecosystemMap:
            return LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.1, green: 0.3, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    var defaultPrompt: String {
        switch self {
        case .cortexPoster: return "CORTEX cinematic robot poster, cyan core glow, void black, premium HUD"
        case .b2tbPillars: return "Back to the Basics 12 pillars, gold orange nebula, doctrine wheel"
        case .controlCenter: return "CORTEX control center holographic dashboard, system map, telemetry"
        case .forgeCharacter: return "FORGE execution layer chibi robot, hammer, cyan glow, industrial forge"
        case .aurionGold: return "AURION legacy command intelligence, gold armor, red core, championship mode"
        case .ecosystemMap: return "CORTEXNODE ecosystem map five layers, neon lanes, founder control"
        }
    }
}

struct PrismMockImageResult: Identifiable {
    let id: String
    let prompt: String
    let preset: PrismVisionPreset
    let style: PrismImageStyle
}
