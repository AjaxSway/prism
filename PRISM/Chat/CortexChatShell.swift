import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CORTEX Chat Shell
// One brain · seven identities · premium mobile-native chat surface.

struct CortexChatShell: View {
    let theme: CortexChatTheme

    @StateObject private var brain = CortexUniverseBrain.shared
    @State private var input = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            chatBackgroundGlow

            VStack(spacing: 0) {
                header
                messageList
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Close") { dismissKeyboard() }
            }
        }
        .onAppear {
            brain.configure(surface: theme.surfaceKey, systemPrompt: theme.systemPrompt)
        }
    }

    private var chatBackgroundGlow: some View {
        let active = brain.pulseState.isActive && !brain.pulseState.isDegraded
        let accent = brain.pulseApp.theme.primary
        return ZStack {
            RadialGradient(
                colors: [accent.opacity(active ? 0.18 : 0.06), .clear],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
            RadialGradient(
                colors: [accent.opacity(active ? 0.08 : 0.03), .clear],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.35), value: brain.pulseState)
    }

    private var header: some View {
        HStack(spacing: 14) {
            SharedCortexBrainPulseView(
                state: brain.pulseState,
                theme: brain.pulseApp.theme,
                size: 56
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(theme.appTitle)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("CORTEX · \(theme.tagline.uppercased())")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.accent.opacity(0.75))
                Text(brain.pulseState.label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(brain.pulseState.isDegraded ? .orange : theme.accent.opacity(0.55))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.panel)
        .overlay(Rectangle().fill(theme.accent.opacity(0.15)).frame(height: 1), alignment: .bottom)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if brain.messages.isEmpty && !brain.isThinking {
                        emptyHero
                    }
                    ForEach(brain.messages) { msg in
                        bubble(msg)
                            .id(msg.id)
                    }
                    if brain.isThinking && (brain.messages.last?.role != .user) {
                        thinkingRow
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(16)
            }
            .onChange(of: brain.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var emptyHero: some View {
        VStack(spacing: 14) {
            SharedCortexBrainPulseView(
                state: brain.pulseState,
                theme: brain.pulseApp.theme,
                size: 160
            )
            Text(theme.greeting)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func bubble(_ msg: CortexBrainMessage) -> some View {
        let isUser = msg.role == .user
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(msg.content)
                .font(.system(size: 14, weight: isUser ? .semibold : .regular))
                .foregroundStyle(isUser ? .white : .white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isUser ? theme.accent.opacity(0.35) : theme.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isUser ? theme.accent.opacity(0.5) : theme.accent.opacity(0.15), lineWidth: 1)
                        )
                )
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private var thinkingRow: some View {
        HStack(spacing: 10) {
            SharedCortexBrainPulseView(
                state: .thinking,
                theme: brain.pulseApp.theme,
                size: 28
            )
            Text("CORTEX thinking")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.accent.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Talk to CORTEX…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($focused)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.accent.opacity(0.2)))

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? theme.accent : .gray.opacity(0.4))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(theme.panel)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !brain.isThinking
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        dismissKeyboard()
        Task {
            let reply = await brain.send(text)
            if !reply.isEmpty, msgRoleAssistant(reply) {
                theme.speak(String(reply.prefix(500)))
            }
        }
    }

    private func dismissKeyboard() {
        focused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func msgRoleAssistant(_ text: String) -> Bool {
        !text.hasPrefix("CORTEX brain unreachable")
    }
}

private extension CortexBrainPulseState {
    var label: String {
        switch self {
        case .idle: return "IDLE"
        case .checking: return "CHECKING"
        case .ready: return "READY"
        case .listening: return "LISTENING"
        case .thinking: return "THINKING"
        case .responding: return "RESPONDING"
        case .speaking: return "SPEAKING"
        case .degraded: return "DEGRADED"
        case .offline: return "OFFLINE"
        case .error: return "ERROR"
        }
    }
}
