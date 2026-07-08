import SwiftUI

// MARK: - PRISM Refraction Studio · Signal Composer · draft-only local workflow

struct PrismRefractionStudioView: View {
    @Bindable var env: ShellEnvironment
    @State private var postText = ""
    @State private var selectedChannels: Set<String> = MockPrismCatalog.defaultSocialChannelIds
    @State private var selectedPrinciple = MockB2TB.today.principleTitle
    @State private var showPrinciplePicker = false
    @State private var showRefractionPreview = false
    @State private var isRefracting = false
    @State private var selectedAudience = "Executive"
    @FocusState private var captionFocused: Bool

    private let audiences = ["Executive", "Brand", "Technical", "Public", "Internal"]
    private var violet: Color { env.config.refractionAccent ?? Color(red: 0.545, green: 0.361, blue: 0.965) }
    private var pink: Color { env.config.refractionPink ?? Color(red: 0.925, green: 0.286, blue: 0.600) }
    private var cyan: Color { Color(red: 0.133, green: 0.827, blue: 0.933) }
    private var gold: Color { Color(red: 0.95, green: 0.65, blue: 0.2) }

    var body: some View {
        let palette = env.palette

        ZStack {
            Color.black.ignoresSafeArea()
            ShellScanlineOverlay(accent: violet, opacity: 0.04)
            ShellAmbientBackground(palette: palette, accentOverride: violet, intensity: 0.55, theme: env.theme, appKind: .prism)

            UniverseHUDCorners(color: violet.opacity(0.52))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ShellAvatarChip(imageName: "ShellPrismAvatar", accent: violet, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            ShellMetallicTitle(text: "PRISM", size: 20, accent: violet)
                            Text("Standalone content workspace · write · approve · distribute")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                    }

                    ShellRefractionBeamDeck(
                        violet: violet,
                        pink: pink,
                        cyan: cyan,
                        orbState: isRefracting ? .executing : env.orbState,
                        onOrbTap: { env.demoOrbCycle() }
                    )
                    .prismLivingCard(accent: violet)

                    HStack(spacing: 6) {
                        ShellStatusBadge(text: "Draft only", palette: palette, tone: .warning)
                        ShellStatusBadge(text: "Approval required", palette: palette, tone: .warning)
                        ShellStatusBadge(text: "Not connected", palette: palette, tone: .neutral)
                    }

                    composeCard

                    refractionButton

                    ShellCanonSectionHeader(
                        title: "PRISM Communication Grid",
                        subtitle: "Purple refraction beam · platform-ready outputs · draft-only",
                        accent: violet
                    )

                    ShellCanonPrismCommunicationGridView(violet: violet, pink: pink, height: 250)

                    ShellCanonSectionHeader(
                        title: "Studio Surfaces",
                        subtitle: "PRISM content workspace · distinct from CORTEX · compose · approve · publish",
                        accent: violet
                    )

                    prismModuleSurfacesStrip(env: env, palette: env.palette, violet: violet)

                    audienceSelectorSection
                    brandVoiceCard
                    channelSection
                    lockedAttributionFooter
                    taglineFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
        .sheet(isPresented: $showPrinciplePicker) { principlePickerSheet }
        .onAppear {
            selectedAudience = env.draftStore.selectedAudience
            selectedPrinciple = env.draftStore.selectedBrandPrinciple
        }
        .onChange(of: selectedAudience) { _, value in
            env.draftStore.selectedAudience = value
        }
        .overlay {
            ShellRefractionPreviewOverlay(
                channels: Array(selectedChannels.compactMap { id in MockPrismCatalog.accounts.first(where: { $0.id == id })?.name }),
                accent: violet,
                secondary: pink,
                isVisible: $showRefractionPreview
            )
        }
    }

    private var brandVoiceCard: some View {
        ShellGlassPanel(palette: env.palette, livingBorder: true, livingSecondary: pink) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Brand Voice · Foundation", systemImage: "text.quote")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gold)
                    Spacer()
                    Text("Doctrine preview · Draft-only")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                }
                Button { showPrinciplePicker = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedPrinciple.uppercased())
                                .font(.system(size: 16, weight: .black, design: .serif))
                                .foregroundColor(.white)
                            Text(MockB2TB.today.hook)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.down.circle.fill").foregroundColor(gold.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    studioGenButton("Create Signal", icon: "text.quote", accent: violet) {
                        postText = MockB2TB.samplePost(principle: selectedPrinciple)
                    }
                    studioGenButton("Open Image Studio", icon: "sparkles.rectangle.stack", accent: gold) {
                        env.selectedTab = .studio
                    }
                }
            }
        }
    }

    private var composeCard: some View {
        ShellGlassPanel(palette: env.palette, livingBorder: true, livingSecondary: pink) {
            VStack(alignment: .leading, spacing: 10) {
                Text("SIGNAL COMPOSER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(violet.opacity(0.8))
                TextEditor(text: $postText)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .focused($captionFocused)
                    .overlay(
                        Group {
                            if postText.isEmpty {
                                Text("Write once · platform-ready outputs appear in draft queue…")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.25))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
        }
    }

    private var channelSection: some View {
        ShellGlassPanel(palette: env.palette) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("REFRACTION OUTPUTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("Draft · \(selectedChannels.count)/\(MockPrismCatalog.accounts.count) · Approval required")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(cyan.opacity(0.7))
                }
                Text("Social · \(MockPrismCatalog.socialAccounts.count) surfaces")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(violet.opacity(0.75))
                ForEach(MockPrismCatalog.socialAccounts) { account in
                    channelRow(account)
                }
                Text("Extended channels")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 4)
                ForEach(MockPrismCatalog.otherAccounts) { account in
                    channelRow(account)
                }
            }
        }
    }

    private func channelRow(_ account: MockPrismAccount) -> some View {
        let selected = selectedChannels.contains(account.id)
        return Button {
            if selected { selectedChannels.remove(account.id) } else { selectedChannels.insert(account.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: account.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? LinearGradient(colors: [violet, pink], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    Text(account.handle).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? cyan : .white.opacity(0.25))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var refractionButton: some View {
        Button {
            Task { await queueRefractionPreview() }
        } label: {
            HStack(spacing: 8) {
                if isRefracting {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "arrow.triangle.branch")
                }
                Text(isRefracting ? "REFRACTING…" : "Queue Refraction Preview")
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.black)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [violet, pink], startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(ShellPressableButtonStyle())
        .disabled(isRefracting || postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityIdentifier("prism-queue-refraction")
        .opacity(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        .overlay(alignment: .bottom) {
            Text(postText.isEmpty ? "Create a signal first · Draft staging" : "Draft-only · Approval before publish")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .offset(y: 22)
        }
    }

    private func queueRefractionPreview() async {
        guard !isRefracting else { return }
        let text = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isRefracting = true
        env.orbState = .executing
        env.impact(.medium)
        env.draftStore.selectedAudience = selectedAudience
        env.draftStore.selectedBrandPrinciple = selectedPrinciple
        env.draftStore.selectedBrandTone = selectedAudience
        try? await Task.sleep(for: .milliseconds(900))
        let draft = env.draftStore.queueRefraction(
            sourceText: text,
            audience: selectedAudience,
            brandPrinciple: selectedPrinciple,
            brandTone: selectedAudience,
            channelIds: Array(selectedChannels)
        )
        showRefractionPreview = true
        env.activityStore.append(
            title: "Refraction queued",
            detail: "\(draft.channelOutputs.count) channels · \(selectedAudience)",
            kind: .command
        )
        try? await Task.sleep(for: .seconds(2.2))
        showRefractionPreview = false
        isRefracting = false
        env.orbState = .success
        env.showToast(
            "Saved to Draft Queue",
            detail: "\(draft.channelOutputs.count) channel outputs · open Approval Gate",
            tone: .success
        )
        try? await Task.sleep(for: .milliseconds(800))
        env.orbState = .idle
    }

    private var audienceSelectorSection: some View {
        ShellGlassPanel(palette: env.palette) {
            VStack(alignment: .leading, spacing: 12) {
                Text("AUDIENCE SELECTOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(violet.opacity(0.75))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(audiences, id: \.self) { audience in
                            Button { selectedAudience = audience } label: {
                                Text(audience)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(selectedAudience == audience ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedAudience == audience
                                            ? LinearGradient(colors: [violet, pink], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text("Brand profile · \(selectedAudience) tone · local refraction")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    private var lockedAttributionFooter: some View {
        ShellHUDBracketPanel(accent: violet) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock.fill").foregroundColor(gold.opacity(0.8))
                    Text("LOCKED ATTRIBUTION")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                Text("Draft channel placeholder · Operator attribution")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("Approval required before publishing · OAuth required later · Draft-only")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    private func prismModuleSurfacesStrip(env: ShellEnvironment, palette: ShellThemePalette, violet: Color) -> some View {
        let ids = ["signal_composer", "refraction_preview", "platform_outputs", "draft_queue", "approval_gate", "image_studio", "campaign_calendar", "audit_trail"]
        let lockedIds: Set<String> = ["platform_outputs", "refraction_preview"]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                if let module = env.config.modules.first(where: { $0.id == id }) {
                    ShellForgeModuleTile(
                        title: module.title,
                        subtitle: module.subtitle,
                        icon: module.icon,
                        accent: violet,
                        palette: palette,
                        moduleId: module.id,
                        livingMotion: true,
                        isLocked: lockedIds.contains(id)
                    ) {
                        env.openModule(module)
                    }
                    .prismStaggerAppear(index: index, accent: violet)
                }
            }
        }
    }

    private var taglineFooter: some View {
        Text("One voice · Many channels · Draft-only until approved")
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(violet.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private var principlePickerSheet: some View {
        NavigationStack {
            List(MockB2TB.principles, id: \.self) { p in
                Button(p) {
                    selectedPrinciple = p
                    showPrinciplePicker = false
                }
            }
            .navigationTitle("Principle")
            .preferredColorScheme(.dark)
        }
    }

    private func studioGenButton(_ title: String, icon: String, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.system(size: 11, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.2)).overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.4), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mock data

struct MockPrismAccount: Identifiable {
    let id: String
    let name: String
    let handle: String
    let icon: String
    var kind: MockPrismChannelKind = .other
}

enum MockPrismChannelKind {
    case social
    case other
}

enum MockPrismCatalog {
    static let socialAccounts: [MockPrismAccount] = [
        MockPrismAccount(id: "x", name: "X", handle: "Not connected", icon: "at", kind: .social),
        MockPrismAccount(id: "ig", name: "Instagram", handle: "Not connected", icon: "camera.fill", kind: .social),
        MockPrismAccount(id: "li", name: "LinkedIn", handle: "Not connected", icon: "briefcase.fill", kind: .social),
        MockPrismAccount(id: "fb", name: "Facebook", handle: "Not connected", icon: "person.2.fill", kind: .social),
        MockPrismAccount(id: "threads", name: "Threads", handle: "Not connected", icon: "at.circle", kind: .social),
        MockPrismAccount(id: "bluesky", name: "Bluesky", handle: "Not connected", icon: "cloud.fill", kind: .social),
    ]

    static let otherAccounts: [MockPrismAccount] = [
        MockPrismAccount(id: "blog", name: "Website / Blog", handle: "Draft channel", icon: "globe", kind: .other),
        MockPrismAccount(id: "email", name: "Email", handle: "Not connected", icon: "envelope.fill", kind: .other),
        MockPrismAccount(id: "sms", name: "SMS", handle: "Not connected", icon: "message.fill", kind: .other),
        MockPrismAccount(id: "pod", name: "Podcast", handle: "Draft channel", icon: "mic.fill", kind: .other),
        MockPrismAccount(id: "yt", name: "YouTube", handle: "Not connected", icon: "play.rectangle.fill", kind: .other),
        MockPrismAccount(id: "tt", name: "TikTok", handle: "Not connected", icon: "music.note", kind: .other),
    ]

    static var accounts: [MockPrismAccount] { socialAccounts + otherAccounts }

    static var defaultSocialChannelIds: Set<String> { Set(socialAccounts.map(\.id)) }
}

struct MockPrismTool: Identifiable {
    let id: String
    let title: String
    let icon: String
}

enum MockPrismTools {
    static let all: [MockPrismTool] = [
        MockPrismTool(id: "image", title: "Image Gen", icon: "sparkles.rectangle.stack"),
        MockPrismTool(id: "caption", title: "Captions", icon: "text.quote"),
        MockPrismTool(id: "hook", title: "Hooks", icon: "bolt.fill"),
        MockPrismTool(id: "thread", title: "Threads", icon: "list.bullet"),
        MockPrismTool(id: "carousel", title: "Carousel", icon: "square.grid.2x2"),
        MockPrismTool(id: "video", title: "Video Script", icon: "film"),
        MockPrismTool(id: "hashtag", title: "Hashtags", icon: "number"),
        MockPrismTool(id: "repurpose", title: "Repurpose", icon: "arrow.triangle.2.circlepath"),
        MockPrismTool(id: "email", title: "Email", icon: "envelope.fill")
    ]
}

enum MockB2TB {
    static let principles = ["Awareness", "Commitment", "Foundation", "Self Leadership", "Relationships", "Legacy", "Gratitude", "Renewal"]
    static let today = (principleTitle: "Relationships", hook: "Strengthening how we treat others.")
    static func samplePost(principle: String) -> String {
        """
        Back to the Basics · \(principle.uppercased())

        Strip away the noise. Return to discipline.

        Guarded. Grounded. Grateful.

        #BackToTheBasics #CORTEX #Discipline
        """
    }
}
