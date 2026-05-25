import SwiftUI
import AVFoundation

// MARK: - PRISM Root — The Interface · Reveals

struct PRISMRootView: View {
    @State private var showSplash = true
    @State private var selectedTab: PTab = .broadcast

    private static let introKey = "prism.introPlayed"
    private static let introText = """
PRISM initialization complete. Connection established. All channels ready. Distribution intelligence online. \
Good evening. I'm PRISM. Your content distribution intelligence layer. Built to take one signal and broadcast \
it everywhere it needs to be — with precision, with timing, with the right voice for every platform. I don't \
just post content. I architect reach. But nothing leaves PRISM without your approval. Ever. This is your \
distribution layer. Your publishing intelligence. Your sovereign signal. Ready to reveal. What would you like to create?
"""

    var body: some View {
        ZStack {
            if showSplash {
                PRISMSplashView { withAnimation(.easeIn(duration: 0.7)) { showSplash = false } }
                    .transition(.opacity)
            } else {
                PRISMCockpitView(selectedTab: $selectedTab)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !UserDefaults.standard.bool(forKey: Self.introKey) else { return }
            UserDefaults.standard.set(true, forKey: Self.introKey)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                VoiceService.speak(Self.introText)
            }
        }
    }
}

// MARK: - Tabs
enum PTab: String, CaseIterable {
    case broadcast = "BROADCAST"
    case reveal    = "REVEAL"
    case queue     = "QUEUE"
    case network   = "NETWORK"
    var icon: String {
        switch self {
        case .reveal:    return "sparkles"
        case .broadcast: return "dot.radiowaves.left.and.right"
        case .queue:     return "tray.full.fill"
        case .network:   return "network"
        }
    }
}

// MARK: - Brand
private struct PBrand {
    static let violet     = Color(red: 0.545, green: 0.361, blue: 0.965)  // #8B5CF6
    static let violetSoft = Color(red: 0.655, green: 0.545, blue: 0.980)  // #A78BFA
    static let pink       = Color(red: 0.925, green: 0.286, blue: 0.600)  // #EC4899
    static let cyan       = Color(red: 0.133, green: 0.827, blue: 0.933)  // #22D3EE
    static let violetDim  = Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.12)
    static let violetLine = Color(red: 0.545, green: 0.361, blue: 0.965).opacity(0.35)
    static let bg         = Color(red: 0.008, green: 0.012, blue: 0.027)  // near-black with purple tint
}

// MARK: - Cockpit
struct PRISMCockpitView: View {
    @Binding var selectedTab: PTab
    @State private var state = PRISMState.shared
    @State private var showSettings = false

    var body: some View {
        ZStack {
            PBrand.bg.ignoresSafeArea()
            PRISMGrid()

            // Prismatic glow
            ZStack {
                RadialGradient(colors: [Color(red:0.36,green:0.0,blue:0.6).opacity(0.3), .clear], center: .init(x:0.2, y:0.5), startRadius: 0, endRadius: 350).ignoresSafeArea()
                RadialGradient(colors: [PBrand.cyan.opacity(0.15), .clear], center: .init(x:0.8, y:0.5), startRadius: 0, endRadius: 300).ignoresSafeArea()
                RadialGradient(colors: [PBrand.pink.opacity(0.1), .clear], center: .init(x:0.5, y:0.2), startRadius: 0, endRadius: 250).ignoresSafeArea()
            }

            PRISMParticleField()
            PRISMScanLine()
            PRISMCorners()

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        PRISMDot()
                        Text("PRISM · CONTENT LAYER · LIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(PBrand.violet).tracking(2)
                    }
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(PBrand.violet.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 10)

                switch selectedTab {
                case .reveal:    PRISMRevealView(state: state)
                case .broadcast: PRISMBroadcastView(state: state)
                case .queue:     PRISMQueueView()
                case .network:   PRISMNetworkView(state: state)
                }

                PRISMTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showSettings) { PRISMSettingsView() }
    }
}

// MARK: - Reveal Tab (Main AI)
struct PRISMRevealView: View {
    @State var state: PRISMState
    @State private var input = ""
    @State private var streaming = false
    @State private var streamText = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                PRISMShimmerTitle()
                Text("AI CONTENT INTELLIGENCE · READY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(PBrand.violet.opacity(0.45)).tracking(3)
            }
            .padding(.top, 12).padding(.bottom, 16)

            PRISMSignalWave()
                .frame(height: 18)
                .padding(.horizontal, 40)
                .padding(.bottom, 14)

            // Channel indicators
            HStack(spacing: 12) {
                ForEach(["X", "IG", "TKTK", "LI", "BSKY", "THREADS"], id: \.self) { ch in
                    channelChip(ch)
                }
            }
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(state.messages) { msg in
                            PRISMMessageRow(msg: msg)
                                .id(msg.id)
                        }
                        if streaming && !streamText.isEmpty {
                            PRISMStreamRow(text: streamText)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16).padding(.bottom, 20)
                }
                .onChange(of: state.messages.count) { withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                .onChange(of: streamText) { proxy.scrollTo("bottom", anchor: .bottom) }
            }

            // Input
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14)).foregroundColor(PBrand.violet.opacity(0.7))
                TextField("", text: $input,
                          prompt: Text("Signal in — reveal anything...")
                    .foregroundColor(PBrand.violet.opacity(0.3))
                    .font(.system(size: 13, design: .monospaced)))
                .font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
                .textFieldStyle(.plain).focused($focused)
                .autocorrectionDisabled().onSubmit { send() }

                if streaming { ProgressView().tint(PBrand.violet).scaleEffect(0.75) }
                else {
                    // Queue last response if one exists
                    let hasResponse = state.messages.last?.role == .assistant
                    if hasResponse && input.isEmpty {
                        Button(action: queueLastResponse) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(PBrand.cyan)
                                .shadow(color: PBrand.cyan.opacity(0.6), radius: 6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: send) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(input.isEmpty ? PBrand.violetLine : PBrand.violet)
                                .shadow(color: input.isEmpty ? .clear : PBrand.violet.opacity(0.6), radius: 8)
                        }
                        .disabled(input.isEmpty).buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Rectangle().fill(PBrand.bg.opacity(0.95))
                .overlay(Rectangle().fill(PBrand.violetLine).frame(height: 1), alignment: .top))
        }
        .onAppear { focused = true }
    }

    private func channelChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 8, weight: .black, design: .monospaced)).tracking(1)
            .foregroundColor(PBrand.violetSoft)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(PBrand.violetDim)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(PBrand.violetLine, lineWidth: 0.8))
            .cornerRadius(4)
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines); guard !q.isEmpty else { return }
        let prompt = q
        input = ""; state.addMessage(role: .user, content: prompt)
        guard state.hasAPIKey else { state.addMessage(role: .system, content: "Neural link offline. Set key in Settings."); return }
        streaming = true; streamText = ""
        Task {
            var full = ""
            do {
                let history = state.messages.filter { $0.role != .system }.suffix(10)
                    .map { (role: $0.role == .user ? "user" : "assistant", content: $0.content) }
                for try await chunk in BrainConnector.shared.stream(messages: Array(history)) { full += chunk; streamText = full }
            } catch { full = "Error: \(error.localizedDescription)" }
            state.addMessage(role: .assistant, content: full)
            state.lastPrompt = prompt
            streamText = ""; streaming = false
            // Speak the first 300 chars of the brain response — ATLAS voice
            let spoken = String(full.prefix(300))
            VoiceService.speak(spoken)
        }
    }

    private func queueLastResponse() {
        guard let last = state.messages.last(where: { $0.role == .assistant }) else { return }
        PostingQueue.shared.addDraft(
            content: last.content,
            platforms: [.x, .instagram, .bluesky, .threads, .linkedin, .facebook, .youtube],
            sourcePrompt: state.lastPrompt
        )
        state.addMessage(role: .system, content: "Added to queue. Approve in QUEUE tab before posting.")
    }
}

private struct PRISMMessageRow: View {
    let msg: PRISMState.BrainMessage
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(msg.timeString).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.2)).frame(width: 56)
            Text(msg.role == .user ? "> SIG" : msg.role == .assistant ? "PRISM" : "SYS")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(msg.role == .user ? .green : msg.role == .assistant ? PBrand.violet : PBrand.pink.opacity(0.7))
                .frame(width: 50)
            Text(msg.content).font(.system(size: 13, design: .monospaced))
                .foregroundColor(msg.role == .system ? .white.opacity(0.4) : .white.opacity(0.88))
                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.vertical, 2)
    }
}

private struct PRISMStreamRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("--:--:--").font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.2)).frame(width: 56)
            Text("PRISM").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundColor(PBrand.violet).frame(width: 50)
            HStack(spacing: 0) {
                Text(text).font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.88))
                Rectangle().fill(PBrand.violet).frame(width: 8, height: 14).opacity(0.8)
                    .modifier(PVioletPulseMod())
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.vertical, 2)
    }
}

// MARK: - Broadcast Tab
struct PlatformInfo: Identifiable {
    let id: String      // internal key (twitter, instagram, etc.)
    let label: String   // display label
    let icon: String
    let color: Color
    let handle: String  // CORTEXNODE connected account
    let blotatoURL: String
}

struct PRISMBroadcastView: View {
    let state: PRISMState
    @State private var queue = PostingQueue.shared
    @State private var broadcasting = false
    @State private var broadcastDone = false
    @State private var glowPulse: CGFloat = 1.0
    @State private var voiceFired = false
    @State private var selectedPlatform: PlatformInfo? = nil

    private let platforms: [PlatformInfo] = [
        PlatformInfo(id: "twitter",   label: "X",         icon: "dot.radiowaves.left.and.right", color: .white,                                          handle: "@CortexNodeAI",           blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "instagram", label: "INSTAGRAM", icon: "camera.circle.fill",            color: Color(red:0.9,green:0.3,blue:0.6),               handle: "@cortexnode.ai",          blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "tiktok",    label: "TIKTOK",    icon: "music.note.tv.fill",            color: .white,                                          handle: "@cortexnode",             blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "linkedin",  label: "LINKEDIN",  icon: "person.crop.circle.fill",       color: Color(red:0.0,green:0.47,blue:0.71),             handle: "George Bayze / CORTEXNODE", blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "bluesky",   label: "BLUESKY",   icon: "cloud.circle.fill",             color: Color(red:0.0,green:0.5,blue:1.0),               handle: "cortexnode.bsky.social",  blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "threads",   label: "THREADS",   icon: "bubble.circle.fill",            color: .white,                                          handle: "@cortexnode.ai",          blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "facebook",  label: "FACEBOOK",  icon: "f.circle.fill",                 color: Color(red:0.23,green:0.35,blue:0.60),            handle: "CORTEXNODE.ai page",      blotatoURL: "https://app.blotato.com"),
        PlatformInfo(id: "youtube",   label: "YOUTUBE",   icon: "play.rectangle.fill",           color: Color(red:1.0,green:0.0,blue:0.0),               handle: "George Bayze (CORTEXNODE)", blotatoURL: "https://app.blotato.com"),
    ]

    private let violet = Color(red:0.545,green:0.361,blue:0.965)
    private let cyan   = Color(red:0.133,green:0.827,blue:0.933)
    private let pink   = Color(red:0.925,green:0.286,blue:0.600)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("BROADCAST")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(violet).tracking(6)
                    Text("ONE SIGNAL IN. EVERY CHANNEL OUT.")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(violet.opacity(0.4)).tracking(3)
                }.padding(.top, 20)

                // PRIMARY CTA — Broadcast button
                Button {
                    guard !broadcasting && queue.approved.count > 0 else { return }
                    broadcastAll()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: broadcastDone ? "checkmark.circle.fill" : "dot.radiowaves.right")
                            .font(.system(size: 20, weight: .bold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(broadcastDone ? "BROADCAST COMPLETE" : "BROADCAST NOW")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .tracking(3)
                            Text(queue.approved.count > 0
                                 ? "\(queue.approved.count) POST\(queue.approved.count == 1 ? "" : "S") APPROVED · READY"
                                 : "NO APPROVED POSTS IN QUEUE")
                                .font(.system(size: 9, design: .monospaced))
                                .opacity(0.65)
                        }
                        Spacer()
                        if broadcasting {
                            ProgressView().tint(violet).scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(queue.approved.count > 0 ? violet : .white.opacity(0.35))
                    .padding(.horizontal, 20).padding(.vertical, 18)
                    .background(queue.approved.count > 0 ? violet.opacity(0.1) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(queue.approved.count > 0 ? violet.opacity(0.6) : .white.opacity(0.1), lineWidth: 1.5)
                    )
                    .cornerRadius(10)
                    .shadow(color: violet.opacity(queue.approved.count > 0 ? 0.4 * glowPulse : 0), radius: 16)
                }
                .buttonStyle(.plain)
                .disabled(broadcasting || queue.approved.count == 0)
                .padding(.horizontal, 20)

                // CORTEX attribution badge — shows what gets appended to every post
                HStack(spacing: 8) {
                    Image(systemName: "signature")
                        .font(.system(size: 11))
                        .foregroundColor(cyan)
                    Text("SIGNATURE APPENDED TO EVERY POST:")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(1)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
                .padding(.horizontal, 20)

                HStack {
                    Text("— Posted by CORTEX · cortexnode.ai")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(cyan)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(cyan.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(cyan.opacity(0.25), lineWidth: 1))
                        .cornerRadius(6)
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Manifesto quick-post
                Button {
                    let manifesto = """
I built CORTEX because I got tired of watching people carry everything on their own.
Not because they weren't capable.
But because they didn't have anything truly in their corner.

232 nights. No team. No outside money. A full-time job during the day. A terminal open every night.

This is CORTEX. Not an app. Not another tool. It is a system.
The kind that makes sure you are never doing this alone again.

cortexnode.ai
"""
                    PostingQueue.shared.addDraft(
                        content: manifesto,
                        platforms: [.x, .instagram, .bluesky, .threads, .linkedin],
                        sourcePrompt: "Founding Manifesto — George Bayze"
                    )
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundColor(pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("QUEUE FOUNDING MANIFESTO")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(pink).tracking(1)
                            Text("George Bayze · Founder Statement")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(pink.opacity(0.7))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(pink.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(pink.opacity(0.25), lineWidth: 1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // Channel grid — tap any platform to manage its connection
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(platforms) { p in
                        let isConnected = !(UserDefaults.standard.string(forKey: "blotato_api_key") ?? "blt_").isEmpty
                        Button { selectedPlatform = p } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle().fill(p.color.opacity(0.12)).frame(width: 62, height: 62)
                                    Circle().stroke(p.color.opacity(isConnected ? 0.7 : 0.25), lineWidth: isConnected ? 2 : 1).frame(width: 62, height: 62)
                                    Image(systemName: p.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(isConnected ? .white : .white.opacity(0.35))
                                        .shadow(color: p.color.opacity(0.9), radius: 5)
                                    // Connection dot
                                    Circle()
                                        .fill(isConnected ? Color.green : Color(red:0.9,green:0.6,blue:0.0))
                                        .frame(width: 10, height: 10)
                                        .shadow(color: isConnected ? Color.green.opacity(0.8) : Color.orange.opacity(0.6), radius: 4)
                                        .offset(x: 22, y: -22)
                                }.shadow(color: p.color.opacity(0.35), radius: 10)
                                Text(p.label).font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(isConnected ? .white.opacity(0.85) : .white.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .sheet(item: $selectedPlatform) { p in
                    PRISMPlatformSheet(platform: p)
                }

                // Queue summary
                HStack(spacing: 20) {
                    queueChip("DRAFT", count: queue.drafts.count, color: violet)
                    queueChip("READY", count: queue.approved.count, color: cyan)
                    queueChip("SENT", count: queue.posted.count, color: pink)
                }
                .padding(.horizontal, 20)
            }.padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glowPulse = 1.5 }
            if !voiceFired {
                voiceFired = true
                VoiceService.speak("PRISM online. Broadcasting to all channels.")
            }
        }
    }

    private func queueChip(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.6)).tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(6)
    }

    private func broadcastAll() {
        broadcasting = true
        let toPost = queue.approved
        Task {
            var successCount = 0
            var failCount = 0
            for post in toPost {
                let results = await BlotatoService.shared.post(content: post.content, platforms: post.platforms)
                let allOk = results.allSatisfy { $0.success }
                if allOk {
                    PostingQueue.shared.markPosted(post)
                    successCount += 1
                } else {
                    failCount += 1
                    let failed = results.filter { !$0.success }.compactMap { $0.error }.joined(separator: ", ")
                    PRISMState.shared.addMessage(role: .system, content: "Broadcast failed for \(post.platforms.count) platform(s): \(failed)")
                }
            }
            broadcasting = false
            broadcastDone = true
            if successCount > 0 {
                PRISMState.shared.addMessage(role: .system, content: "Broadcast complete. \(successCount) post\(successCount == 1 ? "" : "s") sent across all channels.")
            }
        }
    }
}

// MARK: - Platform Connection Sheet

struct PRISMPlatformSheet: View {
    let platform: PlatformInfo
    @Environment(\.dismiss) private var dismiss
    @State private var blotatoKey = UserDefaults.standard.string(forKey: "blotato_api_key") ?? ""
    @State private var saved = false

    private let v  = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let bg = Color(red: 0.008, green: 0.012, blue: 0.027)

    private var isConnected: Bool { !blotatoKey.isEmpty }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            PRISMGrid()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(v.opacity(0.5))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 20)

                Spacer().frame(height: 24)

                // Platform icon + name
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(platform.color.opacity(0.12)).frame(width: 80, height: 80)
                        Circle().stroke(platform.color.opacity(0.5), lineWidth: 2).frame(width: 80, height: 80)
                        Image(systemName: platform.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: platform.color.opacity(0.9), radius: 8)
                    }
                    .shadow(color: platform.color.opacity(0.4), radius: 14)

                    Text(platform.label)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white).tracking(4)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isConnected ? Color.green : Color(red:0.9,green:0.6,blue:0.0))
                            .frame(width: 7, height: 7)
                            .shadow(color: isConnected ? .green : .orange, radius: 4)
                        Text(isConnected ? "CONNECTED" : "API KEY NEEDED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(isConnected ? .green : Color(red:0.9,green:0.6,blue:0.0))
                            .tracking(2)
                    }
                }
                .padding(.bottom, 28)

                // Account info
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONNECTED ACCOUNT")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(v.opacity(0.5)).tracking(2)
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isConnected ? .green : v.opacity(0.3))
                        Text(platform.handle)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(isConnected ? .white.opacity(0.85) : .white.opacity(0.35))
                        Spacer()
                    }
                    .padding(14)
                    .background(v.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(v.opacity(0.2), lineWidth: 1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // API key input
                VStack(alignment: .leading, spacing: 8) {
                    Text("PUBLISHING API KEY")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(v.opacity(0.5)).tracking(2)
                    SecureField("blt_...", text: $blotatoKey)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(v.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(v.opacity(0.3), lineWidth: 1))
                        .cornerRadius(8)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Text("Your Blotato workspace key. All platforms share the same key.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25)).lineSpacing(3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Save + Manage buttons
                VStack(spacing: 10) {
                    Button {
                        UserDefaults.standard.set(blotatoKey, forKey: "blotato_api_key")
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            saved = false
                            dismiss()
                        }
                    } label: {
                        Text(saved ? "SAVED ✓" : "SAVE & CONNECT")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(saved ? .green : v).tracking(2)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(v.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(saved ? Color.green.opacity(0.5) : v.opacity(0.4), lineWidth: 1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if let url = URL(string: platform.blotatoURL) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 12))
                                Text("MANAGE ON BLOTATO")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(.white.opacity(0.45))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Network Tab
struct PRISMNetworkView: View {
    let state: PRISMState
    @State private var brainPingOK: Bool? = nil
    @State private var pingInProgress = false

    private let rows: [(String, String, Color)] = [
        ("SIGNAL RELAY",    "ARMED",        Color(red: 0.133, green: 0.827, blue: 0.933)),
        ("CONTENT ENGINE",  "ACTIVE",       Color(red: 0.545, green: 0.361, blue: 0.965)),
        ("CAPTION AI",      "LINKED",       Color(red: 0.545, green: 0.361, blue: 0.965)),
        ("APPROVAL GATE",   "ENFORCED",     Color(red: 0.925, green: 0.286, blue: 0.600)),
        ("BROADCAST ENGINE","STANDING BY",  Color(red: 0.133, green: 0.827, blue: 0.933)),
        ("QUEUE STORE",     "PERSISTENT",   Color(red: 0.545, green: 0.361, blue: 0.965)),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("NETWORK")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(PBrand.violet).tracking(6)
                    Text("INTELLIGENCE RELAY STATUS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(PBrand.violet.opacity(0.4)).tracking(3)
                }.padding(.top, 20)

                // Brain connection status card
                Button {
                    guard !pingInProgress else { return }
                    Task { await pingBrain() }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(PBrand.violet.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: brainPingOK == true ? "checkmark.circle.fill" : brainPingOK == false ? "exclamationmark.circle.fill" : "circle.dotted")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(brainPingOK == true ? .green : brainPingOK == false ? .red : PBrand.violet)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("CORTEX BRAIN")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.85)).tracking(1)
                            Text(brainPingOK == true ? "api.cortexnode.ai · CONNECTED" :
                                 brainPingOK == false ? "api.cortexnode.ai · UNREACHABLE" :
                                 pingInProgress ? "PINGING..." : "TAP TO TEST CONNECTION")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(brainPingOK == true ? .green.opacity(0.8) :
                                                 brainPingOK == false ? .red.opacity(0.8) :
                                                 PBrand.violet.opacity(0.5))
                        }
                        Spacer()
                        if pingInProgress {
                            ProgressView().tint(PBrand.violet).scaleEffect(0.7)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(PBrand.violet.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(PBrand.violetLine, lineWidth: 1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                // System status rows
                VStack(spacing: 1) {
                    ForEach(rows, id: \.0) { row in
                        HStack {
                            Circle().fill(row.2).frame(width: 5, height: 5)
                                .shadow(color: row.2.opacity(0.9), radius: 3)
                            Text(row.0)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7)).tracking(1)
                            Spacer()
                            Text(row.1)
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(row.2).tracking(1)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color.white.opacity(0.02))
                    }
                }
                .background(PBrand.violet.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(PBrand.violetLine, lineWidth: 1))
                .cornerRadius(8).padding(.horizontal, 20)

                // Version footer
                Text("PRISM · ONE SIGNAL IN · EVERY CHANNEL OUT")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(PBrand.violet.opacity(0.2)).tracking(2)
                    .padding(.top, 4)

            }.padding(.bottom, 100)
        }
        .task { await pingBrain() }
    }

    private func pingBrain() async {
        pingInProgress = true
        do {
            guard let healthURL = URL(string: "https://api.cortexnode.ai/health") else {
                brainPingOK = false
                pingInProgress = false
                return
            }
            var req = URLRequest(url: healthURL)
            req.timeoutInterval = 5
            let (_, resp) = try await URLSession.shared.data(for: req)
            brainPingOK = (resp as? HTTPURLResponse)?.statusCode == 200
        } catch {
            brainPingOK = false
        }
        pingInProgress = false
    }
}

// MARK: - Tab Bar
private struct PRISMTabBar: View {
    @Binding var selectedTab: PTab
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PTab.allCases, id: \.self) { tab in
                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon).font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? PBrand.violet : .white.opacity(0.3))
                            .shadow(color: selectedTab == tab ? PBrand.violet.opacity(0.6) : .clear, radius: 6)
                        Text(tab.rawValue).font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedTab == tab ? PBrand.violet : .white.opacity(0.3))
                        Capsule().fill(selectedTab == tab ? PBrand.violet : .clear).frame(width: 20, height: 2)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }.buttonStyle(.plain)
            }
        }
        .background(Rectangle().fill(.ultraThinMaterial).overlay(Rectangle().fill(Color.black.opacity(0.5))).overlay(Rectangle().fill(PBrand.violetLine.opacity(0.5)).frame(height: 1), alignment: .top))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Splash
struct PRISMSplashView: View {
    let onEnter: () -> Void

    @State private var imageOpacity: Double = 0.0
    @State private var imageScale: CGFloat = 1.08
    @State private var glowPulse = false
    @State private var ringRotation: Double = 0
    @State private var innerRingRotation: Double = 0
    @State private var typedCount = 0
    @State private var subtitleOpacity: Double = 0
    @State private var coreGlow: Double = 0
    @State private var scanLine: CGFloat = -0.1
    @State private var fadeOut = false

    private let accent = Color(red: 0.608, green: 0.188, blue: 1.0)
    private let accentBright = Color(red: 0.784, green: 0.502, blue: 1.0)
    private let titleLetters = Array("PRISM")
    private let subtitle = "ONE SIGNAL. EVERY CHANNEL."
    private let designator = "— PRISM —"
    private let typeInterval: TimeInterval = 0.10

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                Image("PRISMIntroHero")
                    .resizable().interpolation(.high).scaledToFit()
                    .frame(width: geo.size.width)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                    .offset(y: geo.size.height * 0.14)
                    .scaleEffect(imageScale).opacity(imageOpacity).ignoresSafeArea()
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom).frame(height: geo.size.height * 0.28)
                    Spacer()
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.5), Color.black.opacity(0.75)], startPoint: .top, endPoint: .bottom).frame(height: geo.size.height * 0.14)
                }.ignoresSafeArea()
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, accent.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 60).offset(y: geo.size.height * scanLine).blendMode(.screen).allowsHitTesting(false)
                Button { enterApp() } label: {
                    ZStack {
                        Circle().stroke(accent.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [6, 4])).frame(width: 200, height: 200).rotationEffect(.degrees(ringRotation))
                        Circle().stroke(accentBright.opacity(0.15), style: StrokeStyle(lineWidth: 0.8, dash: [3, 5])).frame(width: 140, height: 140).rotationEffect(.degrees(innerRingRotation))
                        Circle().fill(accent.opacity(glowPulse ? 0.14 : 0.04)).frame(width: 120, height: 120)
                        Text("ENTER").font(.system(size: 14, weight: .heavy, design: .monospaced)).foregroundColor(.white).tracking(5).shadow(color: accent, radius: 8).opacity(subtitleOpacity)
                    }
                }.buttonStyle(.plain).position(x: geo.size.width / 2, y: geo.size.height * 0.58).opacity(coreGlow)
                VStack(spacing: 0) {
                    Spacer().frame(height: 64)
                    HStack(spacing: 2) {
                        ForEach(0..<titleLetters.count, id: \.self) { i in
                            Text(String(titleLetters[i])).font(.system(size: 60, weight: .black, design: .monospaced)).foregroundColor(.white)
                                .opacity(i < typedCount ? 1 : 0).scaleEffect(i < typedCount ? 1 : 0.5)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: typedCount)
                        }
                    }.frame(maxWidth: .infinity).minimumScaleFactor(0.6)
                    .shadow(color: accent, radius: 30)
                    .shadow(color: accent.opacity(0.8), radius: 60)
                    .shadow(color: accent.opacity(0.5), radius: 90)
                    Spacer().frame(height: 8)
                    Text(subtitle).font(.system(size: 15, weight: .heavy, design: .monospaced)).foregroundColor(accentBright).tracking(3).multilineTextAlignment(.center).frame(maxWidth: .infinity).opacity(subtitleOpacity)
                    .shadow(color: accent, radius: 12).shadow(color: accent.opacity(0.6), radius: 30)
                    Spacer().frame(height: 6)
                    Text(designator).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(accentBright).tracking(6).multilineTextAlignment(.center).frame(maxWidth: .infinity).opacity(subtitleOpacity)
                    .shadow(color: accent.opacity(0.8), radius: 10)
                    Spacer()
                    VStack(spacing: 6) {
                        Rectangle().fill(LinearGradient(colors: [.clear, accent.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)).frame(width: 240, height: 1)
                        Text("BROADCAST READY").font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(accent.opacity(0.85)).tracking(6)
                    }.opacity(subtitleOpacity)
                    Button { enterApp() } label: { Text("SKIP").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.4)).tracking(3).padding(.horizontal, 24).padding(.vertical, 10) }.buttonStyle(.plain).opacity(subtitleOpacity)
                    Spacer().frame(height: 32)
                }
            }.opacity(fadeOut ? 0 : 1).onAppear { runBootSequence() }
        }
    }

    private func enterApp() {
        withAnimation(.easeIn(duration: 0.3)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onEnter() }
    }

    private func runBootSequence() {
        withAnimation(.easeOut(duration: 1.2)) { imageOpacity = 1; imageScale = 1.0 }
        withAnimation(.easeOut(duration: 1.5)) { coreGlow = 1 }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { ringRotation = 360 }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { innerRingRotation = -360 }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { glowPulse = true }
        withAnimation(.easeInOut(duration: 2.2)) { scanLine = 1.1 }
        for i in 0...titleLetters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * typeInterval) { typedCount = i }
        }
        let end = 0.8 + Double(titleLetters.count) * typeInterval + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + end) { withAnimation(.easeIn(duration: 0.5)) { subtitleOpacity = 1 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { guard !fadeOut else { return }; enterApp() }
    }
}

// MARK: - Shared UI
struct PRISMGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 55
            var x: CGFloat = 0
            while x <= size.width { ctx.stroke(Path { p in p.move(to: .init(x:x,y:0)); p.addLine(to: .init(x:x,y:size.height)) }, with: .color(Color(red:0.545,green:0.361,blue:0.965).opacity(0.05)), lineWidth: 1); x += step }
            var y: CGFloat = 0
            while y <= size.height { ctx.stroke(Path { p in p.move(to: .init(x:0,y:y)); p.addLine(to: .init(x:size.width,y:y)) }, with: .color(Color(red:0.545,green:0.361,blue:0.965).opacity(0.05)), lineWidth: 1); y += step }
        }.allowsHitTesting(false).ignoresSafeArea()
    }
}

struct PRISMDot: View {
    @State private var phase = 0
    @State private var timer: Timer?
    private let colors: [Color] = [Color(red:0.545,green:0.361,blue:0.965), Color(red:0.133,green:0.827,blue:0.933), Color(red:0.925,green:0.286,blue:0.600)]
    var body: some View {
        Circle().fill(colors[phase % 3]).frame(width: 7, height: 7)
            .shadow(color: colors[phase % 3].opacity(0.8), radius: 4)
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
                    withAnimation { phase += 1 }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
}

struct PRISMScanLine: View {
    // Start off-screen using a negative fraction; GeometryReader provides the real height.
    @State private var offset: CGFloat = -600
    var body: some View {
        GeometryReader { geo in
            Rectangle().fill(LinearGradient(colors: [.clear, Color(red:0.545,green:0.361,blue:0.965), Color(red:0.133,green:0.827,blue:0.933), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1).offset(y: offset).opacity(0.4)
                .onAppear {
                    offset = -geo.size.height / 2
                    withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                        offset = geo.size.height
                    }
                }
        }.allowsHitTesting(false).ignoresSafeArea()
    }
}

struct PRISMCorners: View {
    private let c = Color(red: 0.545, green: 0.361, blue: 0.965)
    var body: some View {
        ZStack {
            corner().offset(x: 24, y: 24); corner().scaleEffect(x: -1, y: 1).offset(x: -24, y: 24)
            corner().scaleEffect(x: 1, y: -1).offset(x: 24, y: -24); corner().scaleEffect(x: -1, y: -1).offset(x: -24, y: -24)
        }.allowsHitTesting(false).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    private func corner() -> some View {
        ZStack(alignment: .topLeading) { Rectangle().fill(c).frame(width: 20, height: 1); Rectangle().fill(c).frame(width: 1, height: 20) }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct PVioletPulseMod: ViewModifier {
    @State private var p = false
    private let v = Color(red: 0.545, green: 0.361, blue: 0.965)
    func body(content: Content) -> some View {
        content.shadow(color: p ? v.opacity(0.9) : v.opacity(0.3), radius: p ? 28 : 14)
            .onAppear { withAnimation(.easeInOut(duration: 4).repeatForever()) { p = true } }
    }
}

// MARK: - Shimmer Title
struct PRISMShimmerTitle: View {
    @State private var shimmer: CGFloat = -0.4
    private let violet = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let white  = Color.white

    var body: some View {
        Text("PRISM")
            .font(.system(size: 32, weight: .black, design: .monospaced))
            .tracking(8)
            .foregroundStyle(
                LinearGradient(
                    stops: [
                        .init(color: violet,         location: max(0, shimmer - 0.25)),
                        .init(color: white.opacity(0.95), location: shimmer),
                        .init(color: violet,         location: min(1, shimmer + 0.25)),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: violet.opacity(0.7), radius: 16)
            .onAppear {
                withAnimation(.linear(duration: 2.5).delay(0.8).repeatForever(autoreverses: false)) {
                    shimmer = 1.4
                }
            }
    }
}

// MARK: - Signal Wave
struct PRISMSignalWave: View {
    @State private var phase: CGFloat = 0
    private let violet = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let cyan   = Color(red: 0.133, green: 0.827, blue: 0.933)
    private let pink   = Color(red: 0.925, green: 0.286, blue: 0.600)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height
                let midY = h / 2

                var path = Path()
                let steps = Int(w)
                for i in 0...steps {
                    let x = CGFloat(i)
                    let y = midY + sin((x / w * 4 * CGFloat.pi) + CGFloat(t * 2)) * (h * 0.28)
                         + sin((x / w * 7 * CGFloat.pi) + CGFloat(t * 3.1)) * (h * 0.12)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else       { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                ctx.stroke(path, with: .linearGradient(
                    Gradient(colors: [violet, cyan, pink, violet]),
                    startPoint: CGPoint(x: 0, y: midY),
                    endPoint:   CGPoint(x: w, y: midY)
                ), lineWidth: 1.5)
            }
        }
        .opacity(0.65)
    }
}

// MARK: - Signal Burst Mark
struct PRISMSignalBurst: View {
    @State private var corePulse: CGFloat = 1.0
    @State private var wavePhase: Double = 0
    private let violet = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let cyan   = Color(red: 0.133, green: 0.827, blue: 0.933)
    private let pink   = Color(red: 0.925, green: 0.286, blue: 0.600)

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { tl in
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let cx = w / 2, cy = h / 2
                let t = tl.date.timeIntervalSinceReferenceDate

                // Signal lines radiating outward (like PRISM icon)
                let lineCount = 12
                let colors = [violet, cyan, pink, violet, cyan, pink,
                              violet, cyan, pink, violet, cyan, pink]
                for i in 0..<lineCount {
                    let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(lineCount)
                    let len = w * 0.40 * (0.7 + 0.3 * sin(t * 2 + Double(i) * 0.5))
                    let x2 = cx + cos(angle) * len
                    let y2 = cy + sin(angle) * len
                    // Wave effect along line
                    var line = Path()
                    line.move(to: CGPoint(x: cx, y: cy))
                    let wave: CGFloat = CGFloat(sin(t * 3 + Double(i))) * 8
                    let midX = cx + cos(angle) * len * 0.5 + sin(angle + CGFloat.pi/2) * wave
                    let midY = cy + sin(angle) * len * 0.5 - cos(angle + CGFloat.pi/2) * wave
                    let mid = CGPoint(x: midX, y: midY)
                    line.addQuadCurve(to: CGPoint(x: x2, y: y2), control: mid)

                    let lineColor = colors[i % colors.count]
                    ctx.stroke(line, with: .color(lineColor.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                    // Node at tip
                    let nodeR: CGFloat = 3
                    let node = CGRect(x: x2-nodeR, y: y2-nodeR, width: nodeR*2, height: nodeR*2)
                    ctx.fill(Path(ellipseIn: node), with: .color(lineColor.opacity(0.9)))
                }

                // Core burst
                let cR: CGFloat = 10 * corePulse
                let core = CGRect(x: cx-cR, y: cy-cR, width: cR*2, height: cR*2)
                ctx.addFilter(.shadow(color: .init(violet), radius: 20))
                ctx.fill(Path(ellipseIn: core), with: .color(violet))
                // White center
                let cR2: CGFloat = 4
                let coreWhite = CGRect(x: cx-cR2, y: cy-cR2, width: cR2*2, height: cR2*2)
                ctx.fill(Path(ellipseIn: coreWhite), with: .color(.white.opacity(0.9)))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { corePulse = 1.4 }
        }
        .shadow(color: violet.opacity(0.7), radius: 24)
        .shadow(color: cyan.opacity(0.4), radius: 12)
    }
}

// MARK: - Particle Field
struct PRISMParticleField: View {
    @State private var particles: [(x: CGFloat, y: CGFloat, size: CGFloat, speed: CGFloat, opacity: Double, hue: Double)] =
        (0..<60).map { _ in (
            x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 1...2.5),
            speed: CGFloat.random(in: 8...30),
            opacity: Double.random(in: 0.07...0.30),
            hue: Double.random(in: 0...1)
        )}

    private let colors: [Color] = [
        Color(red:0.545,green:0.361,blue:0.965),  // violet
        Color(red:0.133,green:0.827,blue:0.933),  // cyan
        Color(red:0.925,green:0.286,blue:0.600),  // pink
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let x = (p.x * size.width + CGFloat(t) * p.speed * 0.03)
                        .truncatingRemainder(dividingBy: size.width)
                    let rawY = p.y * size.height - CGFloat(t) * p.speed * 0.01
                    let y = rawY.truncatingRemainder(dividingBy: size.height)
                    let colorIdx = Int(p.hue * 3) % 3
                    let baseColor = colors[colorIdx]
                    let rect = CGRect(x: x, y: y < 0 ? y + size.height : y,
                                      width: p.size, height: p.size)
                    ctx.fill(Path(ellipseIn: rect),
                             with: .color(baseColor
                                .opacity(p.opacity * (0.5 + 0.5 * sin(t * 0.9 + p.hue * 6)))))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Voice (Eric · cjVigY5qzO86Huf0OWal)
enum PVoice {
    static func speak(_ text: String) {
        let elevenKey = UserDefaults.standard.string(forKey: "elevenlabs_api_key") ?? ""
        guard !elevenKey.isEmpty else { return }
        let voiceID = "cjVigY5qzO86Huf0OWal"
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(elevenKey, forHTTPHeaderField: "xi-api-key")
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": ["stability": 0.70, "similarity_boost": 0.80, "style": 0.35, "use_speaker_boost": true]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data, !data.isEmpty else { return }
            // ElevenLabs returns JSON starting with '{' on error — skip non-audio payloads.
            if let first = data.first, first == 0x7B { return }
            DispatchQueue.main.async { PAudioPlayer.shared.play(data) }
        }.resume()
    }
}

private final class PAudioPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = PAudioPlayer()
    private var player: AVAudioPlayer?
    private var currentTempURL: URL?

    func play(_ data: Data) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("p_voice_\(UUID().uuidString).mp3")
        do {
            try data.write(to: url)
            currentTempURL = url
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
        } catch {
            try? FileManager.default.removeItem(at: url)
            currentTempURL = nil
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let url = currentTempURL {
            try? FileManager.default.removeItem(at: url)
            currentTempURL = nil
        }
    }
}

// BrainMessage is defined in Models/PRISMState.swift
