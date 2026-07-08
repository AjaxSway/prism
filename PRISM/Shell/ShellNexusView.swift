import SwiftUI

/// NEXUS — CORTEX Universe identity layer, matching the CORTEX Public design:
/// universe overview, character roster + relationship map, linked apps, lineage,
/// ecosystem shortcuts, and an identity connect card.
struct ShellNexusView: View {
    let env: ShellEnvironment
    @State private var pulse = false
    @State private var orbitAngle: Double = 0
    @State private var showFullRoster = false
    @State private var selectedNode: NexusUniverseNode?

    private var accent: Color { env.palette.accent }
    private var otherNodes: [NexusUniverseNode] {
        NexusUniverseNode.all.filter { $0.id != env.config.appKind.nexusNodeID }
    }

    var body: some View {
        ZStack {
            env.palette.background.ignoresSafeArea()
            RadialGradient(
                colors: [accent.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0, endRadius: 480
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    nexusHeader
                    universeOverviewCard
                    HStack(alignment: .top, spacing: 12) {
                        rosterCard
                        relationshipMapCard
                    }
                    linkedAppsCard
                    HStack(alignment: .top, spacing: 12) {
                        lineageCard
                        shortcutsCard
                    }
                    identityCard
                    statusBar
                }
                .padding(16)
                .padding(.top, 60)
                .padding(.bottom, 200)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { orbitAngle = 360 }
        }
        .sheet(isPresented: $showFullRoster) {
            NexusFullRosterSheet(nodes: NexusUniverseNode.all, accent: accent) { node in
                selectedNode = node
            }
        }
        .sheet(item: $selectedNode) { node in
            NexusNodeDetailSheet(node: node, accent: accent, env: env)
        }
    }

    // MARK: - Header

    private var nexusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXUS")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(colors: [accent, env.config.accentDeep], startPoint: .leading, endPoint: .trailing)
                    )
                    .tracking(3)
                    .shadow(color: accent.opacity(0.5), radius: 14)
                Text("CORTEX UNIVERSE · IDENTITY LAYER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(env.palette.textSecondary)
                    .tracking(1.5)
            }
            Spacer()
            HStack(spacing: 10) {
                Button { showFullRoster = true } label: {
                    Image(systemName: "hexagon")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(accent)
                        .padding(8)
                        .background(accent.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(accent.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button {
                    env.presentConnectLater("Profile", detail: "Sign-in and cross-device identity sync activate when the brain is connected.")
                } label: {
                    HStack(spacing: 5) {
                        Text("PROFILE")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(accent)
                        Circle().fill(env.palette.textSecondary).frame(width: 6, height: 6)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(accent.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accent.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Universe overview

    private var universeOverviewCard: some View {
        nexusGlassCard(radius: 16, padding: 16) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 10) {
                        statLine(icon: "globe", label: "\(NexusUniverseNode.all.count) APPS · UNIVERSE")
                        statLine(icon: "hexagon.fill", label: "\(NexusUniverseNode.all.count) CHARACTERS")
                        statLine(icon: "diamond.fill", label: "4 FACTIONS · LORE")
                        statLine(icon: "infinity", label: "∞ POSSIBILITIES")
                    }
                    Spacer()
                    NexusGalaxyOrb(accent: accent).frame(width: 96, height: 96)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("STATUS").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary).tracking(1)
                            Text("PREVIEW").font(.system(size: 13, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                        }
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("BRAIN").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary).tracking(1)
                            Text(env.brain.isLive ? "RELAY OK" : "LOCAL").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                        }
                    }
                }
                Divider().overlay(accent.opacity(0.12))
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(accent).frame(width: 6, height: 6)
                        Text("UNIVERSE MAP").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                    }
                    Spacer()
                    Button {
                        if env.config.barTabs.contains(.world) { env.selectedTab = .world }
                    } label: {
                        Text("EXPLORE UNIVERSE →")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(accent)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statLine(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(accent).frame(width: 16)
            Text(label).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85))
        }
    }

    // MARK: - Roster

    private var rosterCard: some View {
        nexusGlassCard(radius: 14, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CHARACTERS ROSTER").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).tracking(0.5)
                    Spacer()
                    Button { showFullRoster = true } label: {
                        Text("VIEW ALL").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(NexusUniverseNode.all.prefix(4))) { node in
                        Button { selectedNode = node } label: {
                            VStack(spacing: 4) {
                                nodeAvatar(node, size: 42)
                                Text(node.name).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.9)).lineLimit(1).minimumScaleFactor(0.7)
                                Text(node.role).font(.system(size: 6, weight: .medium, design: .monospaced)).foregroundColor(accent.opacity(0.65)).lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func nodeAvatar(_ node: NexusUniverseNode, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(node.color.opacity(0.12)).frame(width: size, height: size)
            Circle().stroke(node.color.opacity(0.4), lineWidth: 1).frame(width: size, height: size)
            Image(systemName: node.icon).font(.system(size: size * 0.4, weight: .semibold)).foregroundStyle(node.color)
        }
    }

    // MARK: - Relationship map

    private var relationshipMapCard: some View {
        nexusGlassCard(radius: 14, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("RELATIONSHIP MAP").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).tracking(0.5)
                    Spacer()
                    Button {
                        if env.config.barTabs.contains(.world) { env.selectedTab = .world }
                    } label: {
                        Text("VIEW MAP").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                    }
                    .buttonStyle(.plain)
                }
                NexusRelationshipCanvas(nodes: Array(NexusUniverseNode.all.prefix(5)), accent: accent, textColor: env.palette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Linked apps

    private var linkedAppsCard: some View {
        nexusGlassCard(radius: 14, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("LINKED APPS").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).tracking(0.5)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(otherNodes) { node in
                            Button { selectedNode = node } label: {
                                VStack(spacing: 6) {
                                    nodeAvatar(node, size: 44)
                                    Text(node.name).font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).lineLimit(1)
                                    Text(node.role.uppercased()).font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundColor(node.color.opacity(0.85)).lineLimit(1)
                                }
                                .frame(width: 60)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Lineage

    private var lineageCard: some View {
        nexusGlassCard(radius: 14, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("LINEAGE").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).tracking(0.5)
                VStack(spacing: 8) {
                    ForEach(NexusFaction.all, id: \.name) { faction in
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6).fill(faction.color.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(faction.color.opacity(0.3), lineWidth: 0.8))
                                Image(systemName: faction.icon).font(.system(size: 11)).foregroundColor(faction.color)
                            }
                            .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(faction.name).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).lineLimit(1).minimumScaleFactor(0.7)
                                Text(faction.subtitle).font(.system(size: 6, weight: .bold, design: .monospaced)).foregroundColor(faction.color.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ecosystem shortcuts

    private var shortcutsCard: some View {
        nexusGlassCard(radius: 14, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("ECOSYSTEM SHORTCUTS").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.85)).tracking(0.5)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(NexusShortcut.all, id: \.name) { sc in
                        Button {
                            env.presentConnectLater(sc.name, detail: "\(sc.name) activates when your CORTEX account is connected.")
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(sc.color.opacity(0.12))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(sc.color.opacity(0.3), lineWidth: 0.8))
                                    Image(systemName: sc.icon).font(.system(size: 14)).foregroundColor(sc.color)
                                }
                                .frame(height: 32)
                                Text(sc.name).font(.system(size: 6, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary.opacity(0.75))
                                    .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.7)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Identity connect

    private var identityCard: some View {
        nexusGlassCard(radius: 16, padding: 18) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(accent.opacity(0.08)).overlay(Circle().stroke(accent.opacity(0.35), lineWidth: 1)).frame(width: 48, height: 48)
                        Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 20)).foregroundColor(accent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IDENTITY · SYNC").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary).tracking(0.5)
                        Text("Connect Your Account").font(.system(size: 15, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary)
                        Text("Unlock full identity, reputation, and CORTEX universe sync.")
                            .font(.system(size: 10)).foregroundColor(env.palette.textSecondary).lineLimit(2)
                    }
                }
                Button {
                    env.presentConnectLater("Account connection", detail: "Sign-in and identity sync activate when the brain is connected.")
                } label: {
                    Text("CONNECT ACCOUNT TO ACTIVATE")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(1)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(accent))
                        .shadow(color: accent.opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 0) {
            statusItem(icon: "dot.radiowaves.left.and.right", text: "PREVIEW · NET", tint: accent)
            Divider().frame(height: 14).overlay(env.palette.textSecondary.opacity(0.2))
            statusItem(icon: "lock.fill", text: "ON-DEVICE", tint: env.palette.success)
            Divider().frame(height: 14).overlay(env.palette.textSecondary.opacity(0.2))
            statusItem(icon: "checkmark.circle.fill", text: "PREVIEW MODE", tint: accent)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.backgroundElevated)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.1), lineWidth: 0.8)))
    }

    private func statusItem(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8)).foregroundColor(tint.opacity(0.7))
            Text(text).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(tint.opacity(0.65)).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func nexusGlassCard<Content: View>(radius: CGFloat, padding: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content()
            .padding(padding)
            .background(
                ZStack {
                    shape.fill(env.palette.backgroundElevated)
                    shape.fill(LinearGradient(colors: [accent.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            )
            .overlay(shape.stroke(LinearGradient(colors: [accent.opacity(0.22), accent.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Universe nodes

struct NexusUniverseNode: Identifiable {
    let id: String
    let name: String
    let role: String
    let icon: String
    let color: Color

    static let all: [NexusUniverseNode] = [
        NexusUniverseNode(id: "cortex",     name: "CORTEX",  role: "Platform",  icon: "brain.head.profile.fill",  color: Color(red: 0.25, green: 0.56, blue: 1.0)),
        NexusUniverseNode(id: "s0",         name: "S0",      role: "Operator",  icon: "chevron.left.forwardslash.chevron.right", color: Color(red: 0.18, green: 0.88, blue: 0.85)),
        NexusUniverseNode(id: "forge",      name: "FORGE",   role: "Builder",   icon: "hammer.fill",              color: Color(red: 1.0,  green: 0.65, blue: 0.1)),
        NexusUniverseNode(id: "jericho",    name: "JERICHO", role: "Trust",     icon: "shield.fill",              color: Color(red: 0.94, green: 0.27, blue: 0.27)),
        NexusUniverseNode(id: "prism",      name: "PRISM",   role: "Publish",   icon: "triangle.fill",            color: Color(red: 0.78, green: 0.32, blue: 0.95)),
        NexusUniverseNode(id: "cortexnode", name: "NODE",    role: "Network",   icon: "point.3.connected.trianglepath.dotted", color: Color(red: 0.25, green: 0.56, blue: 1.0)),
        NexusUniverseNode(id: "aurion",     name: "AURION",  role: "Invitation Only", icon: "figure.stand",             color: Color(red: 0.35, green: 0.85, blue: 0.65)),
        NexusUniverseNode(id: "babies",     name: "BABIES",  role: "AI Kids",   icon: "person.2.fill",            color: Color(red: 1.0,  green: 0.55, blue: 0.72)),
        NexusUniverseNode(id: "atlas",      name: "ATLAS",   role: "Satellite", icon: "globe.americas.fill",      color: Color(red: 0.4,  green: 0.75, blue: 1.0)),
    ]
}

private extension ShellAppKind {
    /// Maps this app to its own entry in the universe roster, so "Linked Apps" excludes self.
    /// Uses rawValue directly (lowercased) so this stays portable across every app's local
    /// ShellAppKind enum, which may not declare the same case set (e.g. FORGE-only `.forge`).
    var nexusNodeID: String { rawValue.lowercased() }
}

private struct NexusFaction {
    let name: String
    let subtitle: String
    let icon: String
    let color: Color

    static let all: [NexusFaction] = [
        NexusFaction(name: "THE ARCHITECTS", subtitle: "ORIGIN",     icon: "building.columns.fill", color: Color(red: 0.1, green: 0.7, blue: 1.0)),
        NexusFaction(name: "THE GUARDIANS",  subtitle: "PROTECTORS", icon: "shield.fill",           color: Color(red: 0.2, green: 0.9, blue: 0.5)),
        NexusFaction(name: "THE SEEKERS",    subtitle: "EXPLORERS",  icon: "eye.fill",              color: Color(red: 1.0, green: 0.6, blue: 0.1)),
        NexusFaction(name: "THE ECHOES",     subtitle: "WITNESSES",  icon: "waveform.path",         color: Color(red: 0.7, green: 0.3, blue: 1.0)),
    ]
}

private struct NexusShortcut {
    let name: String
    let icon: String
    let color: Color

    static let all: [NexusShortcut] = [
        NexusShortcut(name: "IDENTITY VAULT", icon: "person.badge.key.fill", color: Color(red: 1.0, green: 0.5, blue: 0.1)),
        NexusShortcut(name: "ASSET HUB",      icon: "archivebox.fill",       color: Color(red: 0.25, green: 0.56, blue: 1.0)),
        NexusShortcut(name: "REPUTATION",     icon: "star.fill",             color: Color(red: 0.1, green: 0.85, blue: 0.5)),
        NexusShortcut(name: "MISSIONS",       icon: "checkmark.seal.fill",   color: Color(red: 1.0, green: 0.25, blue: 0.25)),
        NexusShortcut(name: "CHRONICLES",     icon: "books.vertical.fill",   color: Color(red: 0.6, green: 0.2, blue: 1.0)),
        NexusShortcut(name: "EVENTS",         icon: "calendar.badge.plus",   color: Color(red: 0.9, green: 0.15, blue: 0.25)),
    ]
}

// MARK: - Galaxy orb

private struct NexusGalaxyOrb: View {
    let accent: Color

    private struct StarSeed {
        let angle: Double
        let radius: CGFloat
        let size: CGFloat
        let tone: Double
    }

    private static let seeds: [StarSeed] = (0..<90).map { i in
        let fi = Double(i)
        return StarSeed(
            angle: fi * 2.399963 + sin(fi * 1.7) * 0.3,
            radius: CGFloat(0.08 + (sin(fi * 2.3) + 1) * 0.45),
            size: CGFloat(0.6 + abs(sin(fi * 3.1)) * 1.8),
            tone: abs(sin(fi * 0.91))
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxR = min(size.width, size.height) * 0.48
                let spin = t * 0.12

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR, y: center.y - maxR, width: maxR * 2, height: maxR * 2)),
                    with: .color(Color.black.opacity(0.55))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR * 0.95, y: center.y - maxR * 0.72, width: maxR * 1.9, height: maxR * 1.44)),
                    with: .color(Color(red: 0.25, green: 0.05, blue: 0.55).opacity(0.28))
                )

                for seed in Self.seeds {
                    let twinkle = 0.25 + 0.45 * sin(t * 1.7 + seed.tone * 6)
                    let r = maxR * seed.radius
                    let a = seed.angle + spin * 0.35
                    let x = center.x + CGFloat(cos(a)) * r
                    let y = center.y + CGFloat(sin(a)) * r * 0.72
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - seed.size / 2, y: y - seed.size / 2, width: seed.size, height: seed.size)),
                        with: .color(.white.opacity(twinkle * (0.35 + seed.tone * 0.5)))
                    )
                }

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR * 0.28, y: center.y - maxR * 0.2, width: maxR * 0.56, height: maxR * 0.4)),
                    with: .color(Color(red: 0.55, green: 0.2, blue: 0.95).opacity(0.45))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR * 0.16, y: center.y - maxR * 0.12, width: maxR * 0.32, height: maxR * 0.24)),
                    with: .color(accent.opacity(0.72))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - maxR * 0.05, y: center.y - maxR * 0.04, width: maxR * 0.1, height: maxR * 0.08)),
                    with: .color(.white.opacity(0.95))
                )
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(accent.opacity(0.22), lineWidth: 1))
        .shadow(color: accent.opacity(0.35), radius: 14)
    }
}

// MARK: - Relationship map canvas

private struct NexusRelationshipCanvas: View {
    let nodes: [NexusUniverseNode]
    let accent: Color
    let textColor: Color

    private var positions: [(x: CGFloat, y: CGFloat)] {
        [(0.50, 0.50), (0.12, 0.20), (0.88, 0.15), (0.80, 0.82), (0.18, 0.82)]
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                guard !nodes.isEmpty else { return }
                let center = CGPoint(x: size.width * positions[0].x, y: size.height * positions[0].y)

                for (index, _) in nodes.dropFirst().enumerated() where index + 1 < positions.count {
                    let pos = positions[index + 1]
                    let pt = CGPoint(x: size.width * pos.x, y: size.height * pos.y)
                    var path = Path()
                    let mid = CGPoint(
                        x: (center.x + pt.x) / 2 + (pt.y - center.y) * 0.15,
                        y: (center.y + pt.y) / 2 - (pt.x - center.x) * 0.15
                    )
                    path.move(to: center)
                    path.addQuadCurve(to: pt, control: mid)
                    let pulse = 0.18 + 0.12 * sin(t * 1.6 + Double(index))
                    context.stroke(path, with: .color(accent.opacity(pulse)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [5, 4], dashPhase: CGFloat(t * 18 + Double(index) * 8)))
                }

                for (index, node) in nodes.enumerated() where index < positions.count {
                    let pos = positions[index]
                    let pt = CGPoint(x: size.width * pos.x, y: size.height * pos.y)
                    let baseR: CGFloat = index == 0 ? 10 : 7
                    let pulseR = baseR + CGFloat(sin(t * 2.2 + Double(pt.x)) * 1.5)

                    context.fill(
                        Path(ellipseIn: CGRect(x: pt.x - pulseR * 2, y: pt.y - pulseR * 2, width: pulseR * 4, height: pulseR * 4)),
                        with: .color(node.color.opacity(0.18 + 0.08 * sin(t * 2)))
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: pt.x - pulseR, y: pt.y - pulseR, width: pulseR * 2, height: pulseR * 2)),
                        with: .color(node.color)
                    )

                    let label = Text(node.name).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundColor(textColor.opacity(0.8))
                    let resolved = context.resolve(label)
                    let textSize = resolved.measure(in: CGSize(width: 70, height: 20))
                    context.draw(resolved, at: CGPoint(x: pt.x - textSize.width / 2, y: pt.y + pulseR + 3), anchor: .topLeading)
                }
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(accent.opacity(0.12), lineWidth: 0.8))
    }
}

// MARK: - Full roster sheet

private struct NexusFullRosterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let nodes: [NexusUniverseNode]
    let accent: Color
    let onSelect: (NexusUniverseNode) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        Button {
                            dismiss()
                            onSelect(node)
                        } label: {
                            VStack(spacing: 6) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.35))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ZStack {
                                    Circle().fill(node.color.opacity(0.12)).frame(width: 60, height: 60)
                                    Circle().stroke(node.color.opacity(0.4), lineWidth: 1).frame(width: 60, height: 60)
                                    Image(systemName: node.icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(node.color)
                                }
                                Text(node.name).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(.white).lineLimit(1)
                                Text(node.role).font(.system(size: 7, weight: .medium)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("NEXUS ROSTER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(accent)
                }
            }
        }
    }
}

// MARK: - Node detail sheet

extension NexusUniverseNode: Equatable {
    static func == (lhs: NexusUniverseNode, rhs: NexusUniverseNode) -> Bool { lhs.id == rhs.id }
}

private struct NexusNodeDetailSheet: View {
    let node: NexusUniverseNode
    let accent: Color
    let env: ShellEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            env.palette.background.ignoresSafeArea()
            RadialGradient(colors: [node.color.opacity(0.18), env.palette.background], center: .top, startRadius: 0, endRadius: 480)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.14)).frame(width: 36, height: 4).padding(.top, 14).padding(.bottom, 24)

                ZStack {
                    Circle().fill(node.color.opacity(0.12)).frame(width: 100, height: 100)
                    Circle().stroke(node.color.opacity(0.5), lineWidth: 1.5).frame(width: 100, height: 100)
                    Image(systemName: node.icon).font(.system(size: 38, weight: .semibold)).foregroundStyle(node.color)
                }
                .shadow(color: node.color.opacity(0.35), radius: 20)
                .padding(.bottom, 20)

                Text(node.name).font(.system(size: 22, weight: .black, design: .monospaced)).foregroundColor(.white).tracking(2)
                Text(node.role).font(.system(size: 13)).foregroundColor(env.palette.textSecondary).padding(.top, 4)

                Spacer()

                Button("CLOSE") { dismiss() }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(3)
                    .buttonStyle(.plain)
                    .padding(.bottom, 36)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
