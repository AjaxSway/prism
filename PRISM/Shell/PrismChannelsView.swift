import SwiftUI

// MARK: - PRISM Channels · native platform connections · replaces Blotato

struct PrismChannelsView: View {
    @Bindable var env: ShellEnvironment
    @State private var channelManager = PlatformChannelManager.shared
    @State private var connectTarget: Platform?
    @State private var showConnectSheet = false
    @State private var oauthError: String?
    @State private var connectingPlatform: Platform?
    @State private var showQueueSheet = false
    @State private var showComposeSheet = false

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Channels")
                        .font(palette.titleFont)
                        .foregroundColor(palette.textPrimary)
                    Text("Connect platforms · approval required before anything posts")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("prism-channels-title")
                .accessibilityLabel("Channels")

                let connectedCount = channelManager.totalAccountCount
                ShellStatusBadge(
                    text: connectedCount == 0
                        ? "No accounts connected · Tap Connect to authorize"
                        : "\(connectedCount) account\(connectedCount == 1 ? "" : "s") authorized · review still required",
                    palette: palette,
                    tone: connectedCount > 0 ? .success : .warning
                )

                if let oauthError {
                    Text(oauthError)
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.85))
                }

                channelSection(
                    title: "Social Channels",
                    subtitle: "X · Instagram · LinkedIn · Facebook · Threads · Bluesky",
                    platforms: [.x, .instagram, .linkedin, .facebook, .threads, .bluesky],
                    palette: palette,
                    accent: violet
                )

                channelSection(
                    title: "Video & Extended",
                    subtitle: "YouTube · TikTok",
                    platforms: [.youtube, .tiktok],
                    palette: palette,
                    accent: violet
                )

                ShellGlassPanel(palette: palette) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Publishing policy", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(violet)
                        Text("Nothing posts without Approval Gate sign-off. Authorized accounts stay idle until you approve each draft.")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            Button { showComposeSheet = true } label: {
                                Text("NEW DRAFT")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(violet)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(violet.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(violet.opacity(0.5), lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button { showQueueSheet = true } label: {
                                Text("OPEN DRAFT QUEUE")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(violet)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 180)
        }
        .background(ShellScreenBackground(palette: palette))
        .task { await channelManager.refreshGatewayAccounts() }
        .sheet(isPresented: $showQueueSheet) { PRISMQueueView() }
        .sheet(isPresented: $showComposeSheet) {
            PrismComposeDraftSheet(palette: palette, accent: violet) { showComposeSheet = false }
        }
        .sheet(isPresented: $showConnectSheet) {
            if let platform = connectTarget {
                PlatformConnectSheet(platform: platform, palette: palette, accent: violet) {
                    showConnectSheet = false
                }
            }
        }
    }

    private func channelSection(
        title: String,
        subtitle: String,
        platforms: [Platform],
        palette: ShellThemePalette,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ShellCanonSectionHeader(title: title, subtitle: subtitle, accent: accent)
            ForEach(platforms, id: \.self) { platform in
                channelRow(platform, palette: palette, accent: accent)
            }
        }
    }

    private func channelRow(_ platform: Platform, palette: ShellThemePalette, accent: Color) -> some View {
        let gatewayAccounts = channelManager.gatewayAccounts(for: platform)
        let blueskyConnected = platform == .bluesky && channelManager.connection(for: .bluesky).isConnected
        let connected = platform == .bluesky ? blueskyConnected : !gatewayAccounts.isEmpty

        return ShellGlassPanel(palette: palette) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: platform.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(connected ? accent : palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background((connected ? accent : palette.textSecondary).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(platform.rawValue == "X" ? "X (Twitter)" : platform.rawValue.capitalized)
                            .font(palette.bodyFont.weight(.semibold))
                            .foregroundColor(palette.textPrimary)
                        Text(connected
                             ? accountCountLabel(gatewayCount: gatewayAccounts.count, bluesky: blueskyConnected)
                             : "Not connected")
                            .font(.system(size: 10))
                            .foregroundColor(connected ? accent.opacity(0.8) : palette.textSecondary)
                    }

                    Spacer(minLength: 8)

                    connectButtons(platform: platform, connected: connected, accent: accent, palette: palette)
                }

                if !gatewayAccounts.isEmpty {
                    ForEach(gatewayAccounts) { account in
                        HStack {
                            Text(account.handle.map { "@\($0)" } ?? String(account.accountId.prefix(8)) + "…")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(palette.textSecondary)
                            Spacer()
                            Button {
                                Task {
                                    try? await channelManager.disconnectGatewayAccount(account)
                                }
                            } label: {
                                Text("Remove")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red.opacity(0.75))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if platform == .bluesky, let handle = channelManager.connection(for: .bluesky).handle {
                    Text(handle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(palette.textSecondary)
                }
            }
        }
    }

    private func accountCountLabel(gatewayCount: Int, bluesky: Bool) -> String {
        let n = gatewayCount + (bluesky ? 1 : 0)
        return "\(n) account\(n == 1 ? "" : "s")"
    }

    @ViewBuilder
    private func connectButtons(platform: Platform, connected: Bool, accent: Color, palette: ShellThemePalette) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            ShellStatusBadge(
                text: connected ? "Connected" : "Not connected",
                palette: palette,
                tone: connected ? .success : .neutral
            )

            if platform == .bluesky {
                if connected {
                    Button { channelManager.disconnect(.bluesky) } label: {
                        disconnectLabel
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.94))
                } else {
                    Button {
                        connectTarget = platform
                        showConnectSheet = true
                    } label: {
                        connectLabel(accent: accent)
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.94))
                }
            } else if platform.usesGatewayOAuth {
                Button {
                    Task { await startGatewayOAuth(platform: platform) }
                } label: {
                    Group {
                        if connectingPlatform == platform {
                            ProgressView().tint(accent)
                        } else {
                            Text(connected ? "Add Account" : "Connect")
                        }
                    }
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(ShellPressableButtonStyle(scale: 0.94))
                .disabled(connectingPlatform != nil || platform == .facebook || platform == .tiktok)
            } else {
                Button {
                    env.showToast(
                        "Connect later",
                        detail: "\(platform.rawValue) authorization ships in a future gateway update.",
                        tone: .info
                    )
                } label: {
                    Text("Connect later")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(palette.textSecondary.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(palette.backgroundElevated)
                        .clipShape(Capsule())
                }
                .buttonStyle(ShellPressableButtonStyle(scale: 0.94))
            }
        }
    }

    private var disconnectLabel: some View {
        Text("Disconnect")
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundColor(.red.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 0.8))
    }

    private func connectLabel(accent: Color) -> some View {
        Text("Connect")
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundColor(accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 0.8))
    }

    private func startGatewayOAuth(platform: Platform) async {
        oauthError = nil
        connectingPlatform = platform
        defer { connectingPlatform = nil }
        do {
            try await PrismGatewayOAuthService.shared.connect(platform: platform)
        } catch {
            oauthError = error.localizedDescription
        }
    }
}

// MARK: - Platform Connect Sheet

struct PlatformConnectSheet: View {
    let platform: Platform
    let palette: ShellThemePalette
    let accent: Color
    let onDismiss: () -> Void

    @State private var fields: [ConnectField: String] = [:]
    @State private var isSaving = false
    @State private var error: String?

    private var instructions: PlatformConnectInstructions { platform.connectInstructions }
    private let channelManager = PlatformChannelManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Steps
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HOW TO CONNECT")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(accent)
                            .tracking(2)

                        ForEach(Array(instructions.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(accent)
                                    .frame(width: 18)
                                Text(step)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(accent.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if instructions.authType == .gatewayOAuth {
                        if let error {
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 4)
                        }
                        Button {
                            Task { await startGatewayOAuth() }
                        } label: {
                            HStack {
                                if isSaving { ProgressView().tint(.black) }
                                Text(isSaving ? "Opening OAuth…" : "Connect with Gateway")
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving || platform == .facebook || platform == .tiktok)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("CREDENTIALS")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(accent)
                                .tracking(2)

                            ForEach(instructions.fields, id: \.self) { field in
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
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        TextField("Enter \(field.label.lowercased())…", text: binding)
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(.white)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                            .padding(10)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }

                        if let error {
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 4)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            HStack {
                                if isSaving { ProgressView().tint(.black) }
                                Text(isSaving ? "Saving…" : "Save Connection")
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving || !hasRequiredFields)
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.008, green: 0.012, blue: 0.027))
            .navigationTitle(instructions.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hasRequiredFields: Bool {
        instructions.fields.allSatisfy { field in
            !(fields[field] ?? "").isEmpty
        }
    }

    private func save() async {
        isSaving = true
        error = nil

        // For Bluesky, verify credentials before saving
        if platform == .bluesky {
            let handle = fields[.handle] ?? ""
            let appPwd = fields[.appPassword] ?? ""
            let connection = PlatformConnection(
                platform: .bluesky,
                handle: handle,
                accessToken: appPwd,
                isConnected: true
            )
            // Quick test — create a session to validate credentials
            do {
                _ = try await blueskySessionTest(handle: handle, appPassword: appPwd)
                await MainActor.run {
                    channelManager.saveConnection(connection)
                    isSaving = false
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = "Authentication failed: \(error.localizedDescription)"
                    isSaving = false
                }
            }
            return
        }

        await MainActor.run {
            self.error = "Use Connect with Gateway for this platform."
            isSaving = false
        }
    }

    private func startGatewayOAuth() async {
        isSaving = true
        error = nil
        do {
            try await PrismGatewayOAuthService.shared.connect(platform: platform)
            await channelManager.refreshGatewayAccounts()
            isSaving = false
            onDismiss()
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }

    private func blueskySessionTest(handle: String, appPassword: String) async throws -> Bool {
        guard let url = URL(string: "https://bsky.social/xrpc/com.atproto.server.createSession") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["identifier": handle, "password": appPassword])
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.userAuthenticationRequired)
        }
        return true
    }
}

// MARK: - Tone extension for status badge (reuse existing)
// ShellStatusBadge.tone already handles .success, .warning, .neutral
// from ShellComponents.swift — no changes needed here.

// MARK: - Compose draft sheet
// Closes the gap between "connect a real account" and "actually publish something":
// this is the only reachable place in the live app that calls PostingQueue.addDraft,
// which is what makes a post show up in the Queue for approval + dispatch at all.
struct PrismComposeDraftSheet: View {
    let palette: ShellThemePalette
    let accent: Color
    let onDismiss: () -> Void

    @State private var content: String = ""
    @State private var selectedPlatforms: Set<Platform> = []

    private let availablePlatforms: [Platform] = [.x, .instagram, .linkedin, .facebook, .threads, .bluesky, .youtube, .tiktok]

    var body: some View {
        NavigationStack {
            ZStack {
                ShellScreenBackground(palette: palette)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Draft a post locally, pick which connected platforms it targets, then send it to the Queue for approval. Nothing publishes from here — approval happens in the Queue.")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textSecondary)

                        TextEditor(text: $content)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35), lineWidth: 1))
                            .foregroundColor(palette.textPrimary)

                        Text("PLATFORMS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textSecondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                            ForEach(availablePlatforms, id: \.self) { platform in
                                let isSelected = selectedPlatforms.contains(platform)
                                Button {
                                    if isSelected { selectedPlatforms.remove(platform) } else { selectedPlatforms.insert(platform) }
                                } label: {
                                    Text(platform.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(isSelected ? .black : palette.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? accent : Color.white.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            PostingQueue.shared.addDraft(content: content, platforms: Array(selectedPlatforms), sourcePrompt: content)
                            onDismiss()
                        } label: {
                            Text("SAVE TO QUEUE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background((content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPlatforms.isEmpty) ? accent.opacity(0.3) : accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPlatforms.isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }
}
