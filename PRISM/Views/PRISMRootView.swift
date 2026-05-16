import SwiftUI

// MARK: - PRISM Root — The Interface · Reveals

struct PRISMRootView: View {
    @State private var showSplash = true
    @State private var selectedTab: PTab = .reveal

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
    case reveal    = "REVEAL"
    case broadcast = "BROADCAST"
    case network   = "NETWORK"
    var icon: String {
        switch self {
        case .reveal:    return "sparkles"
        case .broadcast: return "dot.radiowaves.left.and.right"
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
                    Text("CONTENT LAYER · v1.0")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(PBrand.violetSoft).tracking(2)
                }
                .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 10)

                switch selectedTab {
                case .reveal:    PRISMRevealView(state: state)
                case .broadcast: PRISMBroadcastView(state: state)
                case .network:   PRISMNetworkView(state: state)
                }

                PRISMTabBar(selectedTab: $selectedTab)
            }
        }
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
                Text("PRISM")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(PBrand.violet).tracking(8)
                    .shadow(color: PBrand.violet.opacity(0.7), radius: 16)
                    .modifier(PVioletPulseMod())
                Text("THE INTERFACE · REVEALS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(PBrand.violet.opacity(0.45)).tracking(3)
            }
            .padding(.top, 12).padding(.bottom, 16)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, PBrand.violet, PBrand.cyan, PBrand.pink, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1).opacity(0.5).padding(.horizontal, 40).padding(.bottom, 14)

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
                .autocorrectionDisabled().textInputAutocapitalization(.never).onSubmit { send() }

                if streaming { ProgressView().tint(PBrand.violet).scaleEffect(0.75) }
                else {
                    Button(action: send) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(input.isEmpty ? PBrand.violetLine : PBrand.violet)
                            .shadow(color: input.isEmpty ? .clear : PBrand.violet.opacity(0.6), radius: 8)
                    }
                    .disabled(input.isEmpty).buttonStyle(.plain)
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
        input = ""; state.addMessage(role: .user, content: q)
        guard state.hasAPIKey else { state.addMessage(role: .system, content: "Neural link offline. Set key."); return }
        streaming = true; streamText = ""
        Task {
            var full = ""
            do {
                let history = state.messages.filter { $0.role != .system }.suffix(10)
                    .map { (role: $0.role == .user ? "user" : "assistant", content: $0.content) }
                for try await chunk in BrainConnector.shared.stream(messages: Array(history)) { full += chunk; streamText = full }
            } catch { full = "Error: \(error.localizedDescription)" }
            state.addMessage(role: .assistant, content: full); streamText = ""; streaming = false
        }
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
    private let platforms: [(String, String, Color)] = [
        ("X",         "dot.radiowaves.left.and.right", .white),
        ("INSTAGRAM", "camera.circle.fill",            Color(red:0.9,green:0.3,blue:0.6)),
        ("TIKTOK",    "music.note.tv.fill",            .white),
        ("LINKEDIN",  "person.crop.circle.fill",       Color(red:0.0,green:0.47,blue:0.71)),
        ("BLUESKY",   "cloud.circle.fill",             Color(red:0.0,green:0.5,blue:1.0)),
        ("THREADS",   "bubble.circle.fill",            .white),
    ]
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("BROADCAST").font(.system(size: 24, weight: .black, design: .monospaced)).foregroundColor(PBrand.violet).tracking(6)
                    Text("ONE SIGNAL IN. EVERY CHANNEL OUT.").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(PBrand.violet.opacity(0.4)).tracking(3)
                }.padding(.top, 20)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(platforms, id: \.0) { p in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(p.2.opacity(0.12)).frame(width: 62, height: 62)
                                Circle().stroke(p.2.opacity(0.5), lineWidth: 1.5).frame(width: 62, height: 62)
                                Image(systemName: p.1).font(.system(size: 22, weight: .semibold)).foregroundColor(.white).shadow(color: p.2.opacity(0.9), radius: 5)
                            }.shadow(color: p.2.opacity(0.35), radius: 10)
                            Text(p.0).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)

                Text("POSTING QUEUE: AWAITING APPROVAL")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(PBrand.violet.opacity(0.5)).tracking(2).padding(.top, 8)
            }.padding(.bottom, 100)
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
                    Circle().stroke(PBrand.violetLine, lineWidth: 1).frame(width: 220, height: 220).modifier(PVioletPulseMod())
                    Circle().stroke(PBrand.cyan.opacity(0.2), lineWidth: 1).frame(width: 160, height: 160)
                    Image(systemName: "sparkles").font(.system(size: 64, weight: .bold)).foregroundColor(PBrand.violet)
                        .shadow(color: PBrand.violet.opacity(0.8), radius: 30).modifier(PVioletPulseMod())
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

// BrainMessage is defined in Models/PRISMState.swift
