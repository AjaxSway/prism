import SwiftUI
import AVFoundation

// MARK: - PRISM Root — The Interface · Reveals

struct PRISMRootView: View {
    @State private var showSplash = true
    @State private var selectedTab: PTab = .signal

    private static let introKey = "prism.introPlayed"
    private static let introText = """
PRISM online. One signal in. Every channel out. \
I am your distribution layer — I take what you create and get it in front of the right people, \
on every platform, with the right voice. Nothing leaves without your approval. \
What are we creating today?
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
    case signal   = "SIGNAL"
    case channels = "CHANNELS"
    case queue    = "QUEUE"
    case studio   = "STUDIO"
    case brain    = "BRAIN"
    case settings = "SETTINGS"
    var icon: String {
        switch self {
        case .signal:   return "dot.radiowaves.left.and.right"
        case .channels: return "sparkles"
        case .queue:    return "tray.full.fill"
        case .studio:   return "photo.stack.fill"
        case .brain:    return "brain.head.profile"
        case .settings: return "gearshape.fill"
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
                        Text("PRISM · CONTENT LAYER · DEMO")
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
                case .signal:   PRISMBroadcastView(state: state)
                case .channels: PRISMRevealView(state: state)
                case .queue:    PRISMQueueView()
                case .studio:   PRISMStudioView()
                case .brain:    CortexChatShell(theme: .app)
                case .settings: PRISMSettingsView()
                }

                PRISMTabBar(selectedTab: $selectedTab)
            }
        }
        .universePremiumChrome(accent: PBrand.violet)
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
                Text("AI CONTENT INTELLIGENCE · PREVIEW")
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
    var platform: Platform?
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
        PlatformInfo(id: "twitter",   label: "X",         icon: "dot.radiowaves.left.and.right", color: .white,                                          handle: "@CortexNodeAI",           platform: .x),
        PlatformInfo(id: "instagram", label: "INSTAGRAM", icon: "camera.circle.fill",            color: Color(red:0.9,green:0.3,blue:0.6),               handle: "@cortexnode.ai",          platform: .instagram),
        PlatformInfo(id: "tiktok",    label: "TIKTOK",    icon: "music.note.tv.fill",            color: .white,                                          handle: "@cortexnode",             platform: .tiktok),
        PlatformInfo(id: "linkedin",  label: "LINKEDIN",  icon: "person.crop.circle.fill",       color: Color(red:0.0,green:0.47,blue:0.71),             handle: "CORTEXNODE",              platform: .linkedin),
        PlatformInfo(id: "bluesky",   label: "BLUESKY",   icon: "cloud.circle.fill",             color: Color(red:0.0,green:0.5,blue:1.0),               handle: "cortexnode.bsky.social",  platform: .bluesky),
        PlatformInfo(id: "threads",   label: "THREADS",   icon: "bubble.circle.fill",            color: .white,                                          handle: "@cortexnode.ai",          platform: .threads),
        PlatformInfo(id: "facebook",  label: "FACEBOOK",  icon: "f.circle.fill",                 color: Color(red:0.23,green:0.35,blue:0.60),            handle: "CORTEXNODE.ai page",      platform: .facebook),
        PlatformInfo(id: "youtube",   label: "YOUTUBE",   icon: "play.rectangle.fill",           color: Color(red:1.0,green:0.0,blue:0.0),               handle: "CORTEXNODE",              platform: .youtube),
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
                            Text(broadcastDone ? "BROADCAST COMPLETE" : "REVIEW FOR BROADCAST")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .tracking(3)
                            Text(queue.approved.count > 0
                                 ? "\(queue.approved.count) POST\(queue.approved.count == 1 ? "" : "S") APPROVED · REVIEW REQUIRED"
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
                        sourcePrompt: "Brand Manifesto"
                    )
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundColor(pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("QUEUE BRAND MANIFESTO")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(pink).tracking(1)
                            Text("Brand voice · Public statement")
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
                        let isConnected = p.platform.map { PlatformChannelManager.shared.isConnected($0) } ?? false
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
            for post in toPost {
                let results = await NativePlatformDispatcher.shared.dispatch(post)
                let anySuccess = results.values.contains { $0.isSuccess }
                let anyFailed = results.values.contains {
                    if case .failed = $0 { return true }
                    return false
                }
                if anySuccess || !anyFailed {
                    PostingQueue.shared.markPosted(post)
                    successCount += 1
                } else {
                    let failMsgs = results.values.compactMap { (r: DispatchResult) -> String? in
                        if case .failed(let m) = r { return m }
                        return nil
                    }.joined(separator: ", ")
                    PRISMState.shared.addMessage(role: .system, content: "Broadcast failed: \(failMsgs)")
                }
            }
            broadcasting = false
            broadcastDone = true
            if successCount > 0 {
                PRISMState.shared.addMessage(role: .system, content: "Broadcast complete. \(successCount) post\(successCount == 1 ? "" : "s") dispatched natively.")
            }
        }
    }
}

// MARK: - Platform Connection Sheet

struct PRISMPlatformSheet: View {
    let platform: PlatformInfo
    @Environment(\.dismiss) private var dismiss
    @State private var channelManager = PlatformChannelManager.shared
    @State private var fields: [ConnectField: String] = [:]
    @State private var isSaving = false
    @State private var isConnectingOAuth = false
    @State private var error: String?

    private let v  = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let bg = Color(red: 0.008, green: 0.012, blue: 0.027)

    private var nativePlatform: Platform? { platform.platform }
    private var gatewayAccounts: [GatewaySocialAccount] {
        guard let p = nativePlatform else { return [] }
        return channelManager.gatewayAccounts(for: p)
    }
    private var isConnected: Bool {
        guard let p = nativePlatform else { return false }
        return channelManager.isConnected(p)
    }
    private var instructions: PlatformConnectInstructions? { nativePlatform?.connectInstructions }
    private var hasRequiredFields: Bool {
        guard let instr = instructions else { return false }
        if instr.authType == .gatewayOAuth { return true }
        return instr.fields.allSatisfy { !(fields[$0] ?? "").isEmpty }
    }
    private var usesGateway: Bool {
        nativePlatform?.usesGatewayOAuth == true && nativePlatform != .bluesky
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            PRISMGrid()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(v.opacity(0.5))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Platform icon + status
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
                                    .fill(isConnected ? Color.green : Color(red: 0.9, green: 0.6, blue: 0.0))
                                    .frame(width: 7, height: 7)
                                    .shadow(color: isConnected ? .green : .orange, radius: 4)
                                Text(isConnected ? "AUTHORIZED" : "NOT CONNECTED")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(isConnected ? .green : Color(red: 0.9, green: 0.6, blue: 0.0))
                                    .tracking(2)
                            }
                        }
                        .padding(.top, 16)

                        if isConnected {
                            connectedAccountsPanel
                        } else if usesGateway, let instr = instructions {
                            gatewayConnectPanel(instr)
                        } else if let instr = instructions {
                            blueskyConnectPanel(instr)
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await channelManager.refreshGatewayAccounts() }
    }

    @ViewBuilder
    private var connectedAccountsPanel: some View {
        if usesGateway {
            VStack(alignment: .leading, spacing: 10) {
                Text("AUTHORIZED ACCOUNTS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(v.opacity(0.5)).tracking(2)
                ForEach(gatewayAccounts) { account in
                    HStack {
                        Text(account.handle.map { "@\($0)" } ?? account.accountId)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Button {
                            Task {
                                try? await channelManager.disconnectGatewayAccount(account)
                            }
                        } label: {
                            Text("REMOVE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(v.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(v.opacity(0.2), lineWidth: 1))
                    .cornerRadius(8)
                }
            }

            Button { Task { await startGatewayOAuth() } } label: {
                HStack {
                    if isConnectingOAuth { ProgressView().tint(.black) }
                    Text(isConnectingOAuth ? "Opening OAuth…" : "Add Account")
                        .font(.system(size: 13, weight: .black, design: .monospaced)).tracking(1)
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(v).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isConnectingOAuth || nativePlatform == .facebook || nativePlatform == .tiktok)
        } else if let handle = nativePlatform.flatMap({ channelManager.connection(for: $0).handle }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AUTHORIZED AS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(v.opacity(0.5)).tracking(2)
                Text(handle)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(v.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(v.opacity(0.2), lineWidth: 1))
                    .cornerRadius(8)
            }
            Button {
                if let p = nativePlatform { channelManager.disconnect(p) }
                dismiss()
            } label: {
                Text("DISCONNECT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.red).tracking(2)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.red.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    .cornerRadius(8)
            }.buttonStyle(.plain)
        }

        if let error {
            Text(error).font(.system(size: 11)).foregroundColor(.red.opacity(0.8))
        }
    }

    @ViewBuilder
    private func gatewayConnectPanel(_ instr: PlatformConnectInstructions) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GATEWAY OAUTH")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(v.opacity(0.5)).tracking(2)
            ForEach(Array(instr.steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(v).frame(width: 18)
                    Text(step)
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14).background(v.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))

        if let error {
            Text(error).font(.system(size: 11)).foregroundColor(.red.opacity(0.8))
        }

        Button { Task { await startGatewayOAuth() } } label: {
            HStack {
                if isConnectingOAuth { ProgressView().tint(.black) }
                Text(isConnectingOAuth ? "Opening OAuth…" : "Connect with Gateway")
                    .font(.system(size: 13, weight: .black, design: .monospaced)).tracking(1)
            }
            .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(v).clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isConnectingOAuth || nativePlatform == .facebook || nativePlatform == .tiktok)
    }

    @ViewBuilder
    private func blueskyConnectPanel(_ instr: PlatformConnectInstructions) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW TO CONNECT")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(v.opacity(0.5)).tracking(2)
            ForEach(Array(instr.steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(v).frame(width: 18)
                    Text(step)
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14).background(v.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 14) {
            Text("CREDENTIALS")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(v.opacity(0.5)).tracking(2)
            ForEach(instr.fields, id: \.self) { field in
                VStack(alignment: .leading, spacing: 4) {
                    Text(field.label)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    let binding = Binding(
                        get: { fields[field] ?? "" },
                        set: { fields[field] = $0 }
                    )
                    if field.isSecure {
                        SecureField("Enter \(field.label.lowercased())…", text: binding)
                            .font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
                            .padding(10).background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        TextField("Enter \(field.label.lowercased())…", text: binding)
                            .font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(10).background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }

        if let error {
            Text(error).font(.system(size: 11)).foregroundColor(.red.opacity(0.8))
        }

        Button { Task { await save() } } label: {
            HStack {
                if isSaving { ProgressView().tint(.black) }
                Text(isSaving ? "Saving…" : "Save Connection")
                    .font(.system(size: 13, weight: .black, design: .monospaced)).tracking(1)
            }
            .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(v).clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isSaving || !hasRequiredFields)
    }

    private func startGatewayOAuth() async {
        guard let p = nativePlatform else { return }
        isConnectingOAuth = true
        error = nil
        do {
            try await PrismGatewayOAuthService.shared.connect(platform: p)
            await channelManager.refreshGatewayAccounts()
        } catch {
            self.error = error.localizedDescription
        }
        isConnectingOAuth = false
    }

    private func save() async {
        guard let p = nativePlatform else { return }
        isSaving = true; error = nil

        if p == .bluesky {
            let handle = fields[.handle] ?? ""
            let appPwd = fields[.appPassword] ?? ""
            do {
                _ = try await blueskySessionTest(handle: handle, appPassword: appPwd)
                await MainActor.run {
                    channelManager.saveConnection(PlatformConnection(platform: p, handle: handle, accessToken: appPwd, isConnected: true))
                    isSaving = false; dismiss()
                }
            } catch {
                await MainActor.run { self.error = "Auth failed: \(error.localizedDescription)"; isSaving = false }
            }
            return
        }

        await MainActor.run {
            self.error = "Use Connect with Gateway for this platform."
            isSaving = false
        }
    }

    private func blueskySessionTest(handle: String, appPassword: String) async throws -> Bool {
        guard let url = URL(string: "https://bsky.social/xrpc/com.atproto.server.createSession") else { throw URLError(.badURL) }
        var req = URLRequest(url: url); req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["identifier": handle, "password": appPassword])
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.userAuthenticationRequired) }
        return true
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
                            Text(brainPingOK == true ? "api.cortexnode.ai · REACHABLE" :
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

// MARK: - Studio Tab
struct PRISMStudioView: View {
    private let violet = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let pink   = Color(red: 0.925, green: 0.286, blue: 0.600)
    private let cyan   = Color(red: 0.133, green: 0.827, blue: 0.933)

    private let tools: [(name: String, icon: String, desc: String, color: Color)] = [
        ("Sora 2",       "film.stack.fill",           "AI video generation",          Color(red: 0.133, green: 0.827, blue: 0.933)),
        ("Runway ML",    "sparkles.rectangle.stack",  "Cinematic video effects",      Color(red: 0.925, green: 0.286, blue: 0.600)),
        ("Opus Clips",   "scissors.badge.ellipsis",   "Auto-clip long-form video",    Color(red: 0.545, green: 0.361, blue: 0.965)),
        ("Canva",        "photo.artframe",             "Visual design & templates",    Color(red: 0.0,   green: 0.75,  blue: 0.55)),
        ("CapCut",       "video.badge.waveform.fill",  "Mobile video editing & AI caps",Color(red: 0.133, green: 0.827, blue: 0.933)),
        ("Final Cut Pro","play.laptopcomputer",        "Pro video editing on Mac",     Color(red: 0.925, green: 0.286, blue: 0.600)),
        ("ElevenLabs",   "waveform.and.mic",           "AI voice synthesis",           Color(red: 0.545, green: 0.361, blue: 0.965)),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("STUDIO")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(violet).tracking(6)
                    Text("YOUR CREATIVE PRODUCTION STACK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(violet.opacity(0.4)).tracking(3)
                }.padding(.top, 20)

                PRISMSignalWave()
                    .frame(height: 18)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(tools, id: \.name) { tool in
                        studioToolCard(tool)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(cyan)
                    Text("Ask PRISM how to use any of these in your workflow")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .padding(.bottom, 100)
        }
    }

    private func studioToolCard(_ tool: (name: String, icon: String, desc: String, color: Color)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(tool.color.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: tool.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tool.color)
                }
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 6, height: 6)
            }
            Text(tool.name)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(.white).tracking(1)
            Text(tool.desc)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tool.color.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tool.color.opacity(0.25), lineWidth: 1))
        .cornerRadius(12)
    }
}

// MARK: - Calendar Stub
struct PRISMCalendarStub: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(colors: [PBrand.violet, PBrand.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("PUBLISH CALENDAR")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Local draft calendar")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(PBrand.violet.opacity(0.6))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(PBrand.violetDim)
                        .clipShape(Capsule())
                }
                .padding(.top, 24)

                VStack(spacing: 1) {
                    ForEach(["Scheduled Posts", "Optimal Times", "Platform Windows", "Content Queue"], id: \.self) { item in
                        HStack {
                            Circle().fill(PBrand.violet.opacity(0.4)).frame(width: 6, height: 6)
                            Text(item)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("PENDING")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(PBrand.violet.opacity(0.5))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(PBrand.violetDim)
                        .overlay(Rectangle().fill(PBrand.violetLine.opacity(0.3)).frame(height: 1), alignment: .bottom)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(PBrand.violetLine, lineWidth: 1))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 100)
        }
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

// BrainMessage is defined in Models/PRISMState.swift
