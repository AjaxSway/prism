import SwiftUI

// MARK: - PRISM Refraction Studio (Signal Composer · Blotato-style mock)

struct PrismRefractionStudioView: View {
    @Bindable var env: ShellEnvironment
    @State private var postText = ""
    @State private var selectedChannels: Set<String> = Set(MockPrismCatalog.accounts.map(\.id))
    @State private var selectedPrinciple = MockB2TB.today.principleTitle
    @State private var showPrinciplePicker = false
    @State private var selectedAudience = "Executive"
    @FocusState private var captionFocused: Bool

    private let audiences = ["Executive", "Founder", "Technical", "Public", "Internal"]
    private var violet: Color { env.config.refractionAccent ?? Color(red: 0.545, green: 0.361, blue: 0.965) }
    private var pink: Color { env.config.refractionPink ?? Color(red: 0.925, green: 0.286, blue: 0.600) }
    private var cyan: Color { Color(red: 0.133, green: 0.827, blue: 0.933) }
    private var gold: Color { Color(red: 0.95, green: 0.65, blue: 0.2) }

    var body: some View {
        let palette = env.palette

        ZStack {
            Color.black.ignoresSafeArea()
            ShellScanlineOverlay(accent: violet, opacity: 0.04)
            ShellAmbientBackground(palette: palette, accentOverride: violet, intensity: 0.55, theme: env.theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ShellAvatarChip(imageName: "ShellPrismAvatar", accent: violet, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            ShellMetallicTitle(text: "PRISM", size: 20, accent: violet)
                            Text("One signal in · Every channel out · One voice")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                    }

                    ShellRefractionBeamDeck(
                        violet: violet,
                        pink: pink,
                        cyan: cyan,
                        orbState: env.orbState,
                        onOrbTap: { env.demoOrbCycle() }
                    )

                    ShellStatusBadge(text: "Draft-only · Approval required · Not connected", palette: palette, tone: .warning)

                    ShellCanonSectionHeader(
                        title: "PRISM Communication Grid",
                        subtitle: "Purple refraction beam · platform-ready outputs · mock only",
                        accent: violet
                    )

                    ShellCanonPrismCommunicationGridView(violet: violet, pink: pink, height: 250)

                    ShellCanonSectionHeader(
                        title: "Studio Surfaces",
                        subtitle: "Composer · outputs · calendar · studio · approval",
                        accent: violet
                    )

                    prismModuleSurfacesStrip(env: env, palette: env.palette, violet: violet)

                    audienceSelectorSection
                    b2tbCard
                    composeCard
                    channelSection
                    refractionButton
                    lockedAttributionFooter
                    taglineFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .sheet(isPresented: $showPrinciplePicker) { principlePickerSheet }
    }

    private var b2tbCard: some View {
        ShellGlassPanel(palette: env.palette) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Back to the Basics", systemImage: "shield.lefthalf.filled")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gold)
                    Spacer()
                    Text("365 doctrine · mock")
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
                    mockGenButton("Create Signal", icon: "text.quote", accent: violet) {
                        postText = MockB2TB.samplePost(principle: selectedPrinciple)
                    }
                    mockGenButton("Image Draft", icon: "sparkles.rectangle.stack", accent: gold) {
                        env.selectedTab = .studio
                    }
                }
            }
        }
    }

    private var composeCard: some View {
        ShellGlassPanel(palette: env.palette) {
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
                    Text("Mock · \(selectedChannels.count)/\(MockPrismCatalog.accounts.count) · Draft-only")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(cyan.opacity(0.7))
                }
                ForEach(MockPrismCatalog.accounts) { account in
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
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                Text("Queue Refraction Preview")
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
        .buttonStyle(.plain)
        .disabled(true)
        .opacity(0.55)
        .overlay(alignment: .bottom) {
            Text("Connect brain · Approval gate required")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .offset(y: 22)
        }
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
                Text("Mock profile · \(selectedAudience) tone · Connect later")
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
        let ids = ["signal_composer", "platform_outputs", "campaign_calendar", "brand_voice", "draft_queue", "distribution_status", "proof_assets", "approval_gate"]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ids, id: \.self) { id in
                if let module = env.config.modules.first(where: { $0.id == id }) {
                    Button { env.openModule(module) } label: {
                        ShellGlassPanel(palette: palette) {
                            HStack(spacing: 8) {
                                Image(systemName: module.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(violet)
                                Text(module.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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

    private func mockGenButton(_ title: String, icon: String, accent: Color, action: @escaping () -> Void) -> some View {
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
}

enum MockPrismCatalog {
    static let accounts: [MockPrismAccount] = [
        MockPrismAccount(id: "blog", name: "Website / Blog", handle: "Draft channel placeholder", icon: "globe"),
        MockPrismAccount(id: "email", name: "Email", handle: "Platform account not connected", icon: "envelope.fill"),
        MockPrismAccount(id: "sms", name: "SMS", handle: "Connect later", icon: "message.fill"),
        MockPrismAccount(id: "pod", name: "Podcast", handle: "Draft channel placeholder", icon: "mic.fill"),
        MockPrismAccount(id: "x", name: "X", handle: "No channel authorized", icon: "at"),
        MockPrismAccount(id: "ig", name: "Instagram", handle: "OAuth required later", icon: "camera.fill"),
        MockPrismAccount(id: "li", name: "LinkedIn", handle: "Platform account not connected", icon: "briefcase.fill"),
        MockPrismAccount(id: "yt", name: "YouTube", handle: "Draft channel placeholder", icon: "play.rectangle.fill"),
        MockPrismAccount(id: "tt", name: "TikTok", handle: "No channel authorized", icon: "music.note"),
        MockPrismAccount(id: "fb", name: "Facebook", handle: "Connect later", icon: "person.2.fill"),
    ]
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
