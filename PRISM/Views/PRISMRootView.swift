import SwiftUI

// MARK: - PRISM Root — The Interface · Reveals

struct PRISMRootView: View {
    @State private var showSplash = true
    @State private var selectedTab: PTab = .broadcast

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
                        Text("BROADCASTING · ALL CHANNELS")
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
                Text("THE INTERFACE · REVEALS")
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
                ForEach(["X", "IG", "TIKTOK", "LI", "SKY"], id: \.self) { ch in
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
struct PRISMBroadcastView: View {
    let state: PRISMState
    @State private var queue = PostingQueue.shared
    @State private var broadcasting = false
    @State private var broadcastDone = false
    @State private var glowPulse: CGFloat = 1.0

    private let platforms: [(String, String, Color)] = [
        ("X",         "dot.radiowaves.left.and.right", .white),
        ("INSTAGRAM", "camera.circle.fill",            Color(red:0.9,green:0.3,blue:0.6)),
        ("TIKTOK",    "music.note.tv.fill",            .white),
        ("LINKEDIN",  "person.crop.circle.fill",       Color(red:0.0,green:0.47,blue:0.71)),
        ("BLUESKY",   "cloud.circle.fill",             Color(red:0.0,green:0.5,blue:1.0)),
        ("THREADS",   "bubble.circle.fill",            .white),
        ("FACEBOOK",  "f.circle.fill",                 Color(red:0.23,green:0.35,blue:0.60)),
        ("YOUTUBE",   "play.rectangle.fill",           Color(red:1.0,green:0.0,blue:0.0)),
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

                // Channel grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(platforms, id: \.0) { p in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(p.2.opacity(0.12)).frame(width: 62, height: 62)
                                Circle().stroke(p.2.opacity(0.5), lineWidth: 1.5).frame(width: 62, height: 62)
                                Image(systemName: p.1)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: p.2.opacity(0.9), radius: 5)
                            }.shadow(color: p.2.opacity(0.35), radius: 10)
                            Text(p.0).font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)

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

// MARK: - Network Tab
struct PRISMNetworkView: View {
    let state: PRISMState
    private let signals: [(String, String)] = [
        ("SIGNAL RELAY",    "ARMED"),
        ("CONTENT ENGINE",  "ACTIVE"),
        ("CAPTION AI",      "LINKED"),
        ("APPROVAL GATE",   "REQUIRED"),
        ("SCHEDULER",       "STANDING BY"),
        ("PRISM BRAIN",     "LINKED"),
    ]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("NETWORK").font(.system(size: 24, weight: .black, design: .monospaced)).foregroundColor(PBrand.violet).tracking(6)
                    Text("INTELLIGENCE RELAY STATUS").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(PBrand.violet.opacity(0.4)).tracking(3)
                }.padding(.top, 20)

                VStack(spacing: 1) {
                    ForEach(signals, id: \.0) { s in
                        HStack {
                            Circle().fill(PBrand.violet).frame(width: 5, height: 5).shadow(color: PBrand.violet.opacity(0.8), radius: 3)
                            Text(s.0).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.7)).tracking(1)
                            Spacer()
                            Text(s.1).font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(PBrand.violet).tracking(1)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12).background(Color.white.opacity(0.02))
                    }
                }
                .background(PBrand.violet.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(PBrand.violetLine, lineWidth: 1))
                .cornerRadius(8).padding(.horizontal, 20)
            }.padding(.bottom, 100)
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

// MARK: - Splash
struct PRISMSplashView: View {
    let onEnter: () -> Void
    @State private var appeared = false
    var body: some View {
        ZStack {
            PBrand.bg.ignoresSafeArea()
            PRISMGrid()
            ZStack {
                RadialGradient(colors: [Color(red:0.36,green:0.0,blue:0.6).opacity(0.35), .clear], center: .init(x:0.2,y:0.5), startRadius:0, endRadius:350).ignoresSafeArea()
                RadialGradient(colors: [PBrand.cyan.opacity(0.15), .clear], center: .init(x:0.8,y:0.5), startRadius:0, endRadius:280).ignoresSafeArea()
            }
            PRISMScanLine()
            PRISMCorners()

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) { PRISMDot(); Text("BROADCASTING · ALL CHANNELS").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(PBrand.violet).tracking(2) }
                    Spacer()
                    Text("CONTENT LAYER · v1.0").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(PBrand.violetSoft).tracking(2)
                }.padding(.horizontal, 24).padding(.top, 60)

                Spacer()

                ZStack {
                    Circle().stroke(PBrand.violetLine, lineWidth: 1).frame(width: 280, height: 280).modifier(PVioletPulseMod())
                    Circle().stroke(PBrand.cyan.opacity(0.15), lineWidth: 1).frame(width: 210, height: 210).modifier(PVioletPulseMod())
                    PRISMSignalBurst()
                        .frame(width: 200, height: 200)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                }.opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 0) {
                    Text("PRISM").font(.system(size: 44, weight: .black, design: .monospaced)).foregroundColor(PBrand.violet).tracking(8)
                        .shadow(color: PBrand.violet.opacity(0.8), radius: 24).modifier(PVioletPulseMod())
                    Text("THE INTELLIGENCE RELAY NETWORK").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(PBrand.violet.opacity(0.5)).tracking(3).padding(.top, 8)
                    Rectangle().fill(LinearGradient(colors: [.clear, PBrand.violet, PBrand.cyan, PBrand.pink, .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 140, height: 1).opacity(0.5).padding(.vertical, 18)
                    Text("One signal in.\nEvery channel out.\nZero noise.").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center).lineSpacing(4)
                    Button(action: onEnter) {
                        Text("ACTIVATE PRISM").font(.system(size: 11, weight: .black, design: .monospaced)).foregroundColor(PBrand.violetSoft).tracking(3)
                            .padding(.horizontal, 40).padding(.vertical, 14)
                            .background(PBrand.violetDim)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(PBrand.violetLine, lineWidth: 1)).cornerRadius(4)
                    }.buttonStyle(.plain).padding(.top, 24)
                }.padding(.bottom, 60).opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { appeared = true } }
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
    private let colors: [Color] = [Color(red:0.545,green:0.361,blue:0.965), Color(red:0.133,green:0.827,blue:0.933), Color(red:0.925,green:0.286,blue:0.600)]
    var body: some View {
        Circle().fill(colors[phase % 3]).frame(width: 7, height: 7)
            .shadow(color: colors[phase % 3].opacity(0.8), radius: 4)
            .onAppear { Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in withAnimation { phase += 1 } } }
    }
}

struct PRISMScanLine: View {
    @State private var offset: CGFloat = -UIScreen.main.bounds.height / 2
    var body: some View {
        GeometryReader { geo in
            Rectangle().fill(LinearGradient(colors: [.clear, Color(red:0.545,green:0.361,blue:0.965), Color(red:0.133,green:0.827,blue:0.933), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1).offset(y: offset).opacity(0.4)
                .onAppear { withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) { offset = geo.size.height } }
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
                    let y = midY + sin((x / w * 4 * .pi) + CGFloat(t * 2)) * (h * 0.28)
                         + sin((x / w * 7 * .pi) + CGFloat(t * 3.1)) * (h * 0.12)
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
                    let angle = CGFloat(i) * .pi * 2 / CGFloat(lineCount)
                    let len = w * 0.40 * (0.7 + 0.3 * sin(t * 2 + Double(i) * 0.5))
                    let x2 = cx + cos(angle) * len
                    let y2 = cy + sin(angle) * len
                    // Wave effect along line
                    var line = Path()
                    line.move(to: CGPoint(x: cx, y: cy))
                    let wave: CGFloat = CGFloat(sin(t * 3 + Double(i))) * 8
                    let midX = cx + cos(angle) * len * 0.5 + sin(angle + .pi/2) * wave
                    let midY = cy + sin(angle) * len * 0.5 - cos(angle + .pi/2) * wave
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
