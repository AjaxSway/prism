import SwiftUI

// MARK: - CORTEX Tracker demo models (layout inspired by tracker.network · demo data only)

private enum GamingPlatform: String, CaseIterable, Identifiable {
    case pc = "PC"
    case psn = "PSN"
    case xbl = "XBL"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pc: return "desktopcomputer"
        case .psn: return "gamecontroller.fill"
        case .xbl: return "xbox.logo"
        }
    }

    var color: Color {
        switch self {
        case .pc: return Color(red: 0.0, green: 0.85, blue: 1.0)
        case .psn: return Color(red: 0.1, green: 0.4, blue: 0.95)
        case .xbl: return Color(red: 0.1, green: 0.72, blue: 0.2)
        }
    }
}

private enum GamingRank: String {
    case copper = "COPPER", bronze = "BRONZE", silver = "SILVER", gold = "GOLD"
    case platinum = "PLATINUM", emerald = "EMERALD", diamond = "DIAMOND", champions = "CHAMPION"

    var color: Color {
        switch self {
        case .copper:    return Color(red: 0.72, green: 0.38, blue: 0.18)
        case .bronze:    return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:    return Color(red: 0.72, green: 0.72, blue: 0.76)
        case .gold:      return Color(red: 1.00, green: 0.82, blue: 0.00)
        case .platinum:  return Color(red: 0.00, green: 0.88, blue: 0.92)
        case .emerald:   return Color(red: 0.08, green: 0.90, blue: 0.42)
        case .diamond:   return Color(red: 0.68, green: 0.28, blue: 1.00)
        case .champions: return Color(red: 1.00, green: 0.28, blue: 0.18)
        }
    }

    var icon: String {
        switch self {
        case .copper:    return "hexagon.fill"
        case .bronze, .silver: return "shield.fill"
        case .gold:      return "star.fill"
        case .platinum:  return "diamond.fill"
        case .emerald:   return "seal.fill"
        case .diamond:   return "crown.fill"
        case .champions: return "trophy.fill"
        }
    }
}

private enum GamingRole: String {
    case attack = "ATK", defense = "DEF"
    var color: Color {
        switch self {
        case .attack:  return Color(red: 1.0, green: 0.42, blue: 0.16)
        case .defense: return Color(red: 0.16, green: 0.58, blue: 1.0)
        }
    }
}

private enum GamingMatchResult: String {
    case win = "WIN", loss = "LOSS", abnd = "ABND"
    var color: Color {
        switch self {
        case .win:  return Color(red: 0.08, green: 0.90, blue: 0.42)
        case .loss: return Color(red: 1.00, green: 0.22, blue: 0.22)
        case .abnd: return Color(red: 1.00, green: 0.60, blue: 0.00)
        }
    }
}

private struct GamingOperatorStat: Identifiable {
    var id = UUID()
    var name: String
    var role: GamingRole
    var kills: Int
    var deaths: Int
    var wins: Int
    var matches: Int
    var accentColor: Color
    var kd: Double { Double(kills) / Double(max(1, deaths)) }
    var winRate: Double { Double(wins) / Double(max(1, matches)) * 100 }
}

private struct GamingRecentMatch: Identifiable {
    var id = UUID()
    var map: String
    var result: GamingMatchResult
    var kills: Int
    var deaths: Int
    var assists: Int
    var minutesAgo: Int
    var kd: Double { Double(kills) / Double(max(1, deaths)) }
    var timeText: String { minutesAgo < 60 ? "\(minutesAgo)m ago" : "\(minutesAgo / 60)h ago" }
}

private struct GamingPlayerProfile {
    var username: String
    var platform: GamingPlatform
    var level: Int
    var rank: GamingRank
    var rankTier: Int
    var rankPoints: Int
    var maxRankPoints: Int
    var seasonMatches: Int
    var seasonWins: Int
    var seasonKills: Int
    var seasonDeaths: Int
    var seasonHeadshots: Int
    var hoursPlayed: Int
    var operators: [GamingOperatorStat]
    var recentMatches: [GamingRecentMatch]

    var winRate: Double { Double(seasonWins) / Double(max(1, seasonMatches)) * 100 }
    var kd: Double { Double(seasonKills) / Double(max(1, seasonDeaths)) }
    var hsp: Double { Double(seasonHeadshots) / Double(max(1, seasonKills)) * 100 }
    var rankProgressPct: Double { Double(rankPoints) / Double(max(1, maxRankPoints)) }
}

private func gamingDemoProfile(_ alias: String) -> GamingPlayerProfile {
    GamingPlayerProfile(
        username: alias.uppercased(),
        platform: .pc,
        level: 312, rank: .gold, rankTier: 2, rankPoints: 3_420, maxRankPoints: 4_000,
        seasonMatches: 186, seasonWins: 108, seasonKills: 1_284, seasonDeaths: 892, seasonHeadshots: 514,
        hoursPlayed: 847,
        operators: [
            GamingOperatorStat(name: "JÄGER", role: .defense, kills: 312, deaths: 198, wins: 74, matches: 102, accentColor: Color(red: 0.6, green: 0.6, blue: 0.7)),
            GamingOperatorStat(name: "ASH", role: .attack, kills: 287, deaths: 172, wins: 68, matches: 94, accentColor: Color(red: 1.0, green: 0.42, blue: 0.16)),
            GamingOperatorStat(name: "VALKYRIE", role: .defense, kills: 198, deaths: 145, wins: 52, matches: 78, accentColor: Color(red: 0.3, green: 0.5, blue: 0.9)),
            GamingOperatorStat(name: "SLEDGE", role: .attack, kills: 176, deaths: 140, wins: 44, matches: 66, accentColor: Color(red: 0.9, green: 0.6, blue: 0.1)),
        ],
        recentMatches: [
            GamingRecentMatch(map: "BORDER", result: .win, kills: 8, deaths: 2, assists: 3, minutesAgo: 14),
            GamingRecentMatch(map: "COASTLINE", result: .loss, kills: 3, deaths: 4, assists: 1, minutesAgo: 47),
            GamingRecentMatch(map: "CLUBHOUSE", result: .win, kills: 6, deaths: 1, assists: 2, minutesAgo: 82),
            GamingRecentMatch(map: "BANK", result: .win, kills: 7, deaths: 3, assists: 4, minutesAgo: 118),
        ]
    )
}

/// GAMING — full tracker-style dashboard, matching the CORTEX Public design:
/// player card, season stats, top operators, recent matches, platforms, quick actions, music.
struct ShellGamingView: View {
    let env: ShellEnvironment
    @State private var ambientPulse = false
    @State private var username = ""
    @State private var platform: GamingPlatform = .pc
    @State private var profile: GamingPlayerProfile
    @State private var opFilter: GamingRole?
    @State private var showingAllOps = false
    @State private var showPlatformSheet = false
    @State private var selectedPlatform = ""

    init(env: ShellEnvironment) {
        self.env = env
        _profile = State(initialValue: gamingDemoProfile(env.config.alias))
    }

    private var accent: Color { env.palette.accent }

    var body: some View {
        ZStack {
            backdrop
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerBar
                    sampleDataBanner
                    searchBar
                    playerCard
                    seasonStats
                    operatorSection
                    matchHistorySection
                    platformCommandRow
                    quickActionsRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .padding(.bottom, 200)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { ambientPulse = true }
        }
        .sheet(isPresented: $showPlatformSheet) {
            GamingPlatformConnectSheet(platformName: selectedPlatform, accent: accent, env: env)
        }
    }

    private var backdrop: some View {
        ZStack {
            env.palette.background.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(ambientPulse ? 0.24 : 0.12), .clear], center: .topTrailing, startRadius: 20, endRadius: 420)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GAMING")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: accent.opacity(ambientPulse ? 0.9 : 0.45), radius: ambientPulse ? 16 : 7)
                Text("\(env.config.displayName) Stats · Library · Preview")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(env.palette.textSecondary.opacity(0.85))
            }
            Spacer()
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 24))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.75), radius: 14)
        }
    }

    private var sampleDataBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill").font(.system(size: 11)).foregroundColor(env.palette.warning)
            Text("DEMO PROFILE · layout inspired by tracker.network")
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(env.palette.textSecondary)
                .lineLimit(2)
            Spacer()
            Text("SAMPLE")
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundColor(env.palette.warning)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(env.palette.warning.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.backgroundElevated)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(env.palette.warning.opacity(0.25), lineWidth: 0.8)))
    }

    // MARK: - Search

    private var searchBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(GamingPlatform.allCases) { plat in
                    Button {
                        platform = plat
                        profile.platform = plat
                        haptic()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: plat.icon).font(.system(size: 11, weight: .bold))
                            Text(plat.rawValue).font(.system(size: 11, weight: .heavy, design: .monospaced))
                        }
                        .foregroundColor(platform == plat ? .black : plat.color)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(platform == plat ? plat.color : Color.clear)
                    }
                    .buttonStyle(.plain)
                    if plat != GamingPlatform.allCases.last {
                        Divider().frame(height: 20).overlay(accent.opacity(0.3))
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(env.palette.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.35), lineWidth: 0.8)))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(env.palette.textSecondary).font(.system(size: 14, weight: .semibold))
                TextField("", text: $username, prompt: Text("ENTER USERNAME").font(.system(size: 12, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary.opacity(0.5)))
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundColor(env.palette.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !username.isEmpty {
                    Button { username = ""; haptic() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(env.palette.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    haptic()
                    let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        profile.username = trimmed.uppercased()
                    } else {
                        profile = gamingDemoProfile(env.config.alias)
                        profile.platform = platform
                    }
                } label: {
                    Text("SEARCH").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.backgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35), lineWidth: 0.8)))
        }
        .gamingPanel(accent: accent, env: env)
    }

    // MARK: - Player card

    private var playerCard: some View {
        let p = profile
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(p.rank.color.opacity(0.15)).frame(width: 60, height: 60)
                    .overlay(Circle().stroke(p.rank.color.opacity(0.7), lineWidth: 1.5))
                    .shadow(color: p.rank.color.opacity(ambientPulse ? 0.7 : 0.35), radius: ambientPulse ? 14 : 6)
                Image(systemName: p.rank.icon).font(.system(size: 26, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [p.rank.color, p.rank.color.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(p.username).font(.system(size: 15, weight: .black, design: .monospaced)).foregroundColor(env.palette.textPrimary).lineLimit(1).minimumScaleFactor(0.8)
                    Image(systemName: platform.icon).font(.system(size: 11)).foregroundColor(platform.color)
                }
                HStack(spacing: 6) {
                    Text("LVL \(p.level)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(accent.opacity(0.85))
                    Text("·").foregroundColor(env.palette.textSecondary)
                    Text("\(p.rank.rawValue) \(p.rankTier)").font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(p.rank.color)
                }
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(env.palette.backgroundElevated).frame(height: 5)
                            Capsule().fill(p.rank.color).frame(width: geo.size.width * p.rankProgressPct, height: 5)
                        }
                    }
                    .frame(height: 5)
                    Text("\(p.rankPoints) RP").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(p.rank.color)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(p.hoursPlayed)H").font(.system(size: 15, weight: .black, design: .monospaced)).foregroundColor(accent)
                Text("PLAYED").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(env.palette.textSecondary)
            }
        }
        .gamingPanel(accent: p.rank.color, env: env)
    }

    // MARK: - Season stats

    private var seasonStats: some View {
        let p = profile
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SEASON · RANKED").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent).tracking(1)
                Spacer()
                Text("\(p.seasonMatches) MATCHES").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(env.palette.textSecondary)
            }
            HStack(spacing: 8) {
                statTile("K/D", String(format: "%.2f", p.kd), p.kd >= 1.0 ? env.palette.success : env.palette.error)
                statTile("W/L %", String(format: "%.1f%%", p.winRate), p.winRate >= 50 ? env.palette.success : env.palette.error)
                statTile("HS %", String(format: "%.1f%%", p.hsp), Color(red: 1.0, green: 0.82, blue: 0.0))
                statTile("KILLS", "\(p.seasonKills)", accent)
            }
        }
        .gamingPanel(accent: accent, env: env)
    }

    private func statTile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 15, weight: .black, design: .monospaced)).foregroundColor(color).shadow(color: color.opacity(0.55), radius: 6)
            Text(label).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary).tracking(0.8)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.background.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 0.8)))
    }

    // MARK: - Operators

    private var operatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP OPERATORS").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent).tracking(1)
                Spacer()
                HStack(spacing: 6) {
                    roleChip(nil)
                    roleChip(.attack)
                    roleChip(.defense)
                }
            }
            let ops = profile.operators.filter { opFilter == nil || $0.role == opFilter }
            let displayOps = showingAllOps ? ops : Array(ops.prefix(4))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(displayOps) { op in operatorCard(op) }
            }
            if ops.count > 4 {
                Button {
                    withAnimation(.spring(response: 0.3)) { showingAllOps.toggle() }
                    haptic()
                } label: {
                    HStack(spacing: 6) {
                        Text(showingAllOps ? "SHOW LESS" : "VIEW ALL \(ops.count) OPS").font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(accent)
                        Image(systemName: showingAllOps ? "chevron.up" : "chevron.down").font(.system(size: 9, weight: .bold)).foregroundColor(accent)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .gamingPanel(accent: accent, env: env)
    }

    private func roleChip(_ role: GamingRole?) -> some View {
        let label = role?.rawValue ?? "ALL"
        let color: Color = role?.color ?? accent
        let isSelected = opFilter == role
        return Button {
            opFilter = role
            haptic()
        } label: {
            Text(label).font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(isSelected ? color : color.opacity(0.15)))
                .overlay(Capsule().stroke(color.opacity(isSelected ? 0 : 0.5), lineWidth: 0.7))
        }
        .buttonStyle(.plain)
    }

    private func operatorCard(_ op: GamingOperatorStat) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(op.accentColor.opacity(0.18)).frame(width: 40, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(op.accentColor.opacity(0.5), lineWidth: 0.8))
                Text(String(op.name.prefix(2))).font(.system(size: 13, weight: .black, design: .monospaced)).foregroundColor(op.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(op.name).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary).lineLimit(1).minimumScaleFactor(0.8)
                    Text(op.role.rawValue).font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundColor(op.role.color)
                        .padding(.horizontal, 4).padding(.vertical, 2).background(Capsule().fill(op.role.color.opacity(0.15)))
                }
                HStack(spacing: 8) {
                    Text("K/D \(String(format: "%.2f", op.kd))").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(op.kd >= 1.0 ? env.palette.success : env.palette.error)
                    Text("W \(String(format: "%.0f%%", op.winRate))").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(accent.opacity(0.85))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(env.palette.background.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(op.accentColor.opacity(0.25), lineWidth: 0.7)))
    }

    // MARK: - Match history

    private var matchHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT MATCHES").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent).tracking(1)
            VStack(spacing: 6) {
                ForEach(profile.recentMatches) { match in matchRow(match) }
            }
        }
        .gamingPanel(accent: accent, env: env)
    }

    private func matchRow(_ match: GamingRecentMatch) -> some View {
        HStack(spacing: 10) {
            Text(match.result.rawValue).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundColor(.black)
                .frame(width: 36).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(match.result.color))
            Text(match.map).font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(match.kills)/\(match.deaths)/\(match.assists)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(match.kd >= 1.0 ? env.palette.success : env.palette.error)
                Text("K/D/A").font(.system(size: 7, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textSecondary)
            }
            Text(match.timeText).font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(env.palette.textSecondary).frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(env.palette.background.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(match.result.color.opacity(0.25), lineWidth: 0.7)))
    }

    // MARK: - Platforms

    private var platformCommandRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PLATFORMS · PREVIEW HOOKS").font(.system(size: 13, weight: .heavy, design: .monospaced)).foregroundStyle(accent).tracking(1)
            HStack(spacing: 10) {
                platformButton("PS5", "gamecontroller.fill", Color(red: 0.0, green: 0.42, blue: 1.0)) { selectedPlatform = "PS5"; showPlatformSheet = true }
                platformButton("XBOX", "xbox.logo", env.palette.success) { selectedPlatform = "XBOX"; showPlatformSheet = true }
                platformButton("DISCORD", "bubble.left.and.bubble.right.fill", Color(red: 0.55, green: 0.48, blue: 1.0)) { selectedPlatform = "DISCORD"; showPlatformSheet = true }
            }
        }
        .gamingPanel(accent: accent, env: env)
    }

    private func platformButton(_ title: String, _ icon: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24, weight: .bold)).foregroundStyle(tint).shadow(color: tint.opacity(0.65), radius: 9)
                Text(title).font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary)
                Text("CONNECT").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(tint.opacity(0.85))
            }
            .frame(maxWidth: .infinity).frame(height: 86)
            .background(RoundedRectangle(cornerRadius: 13).fill(LinearGradient(colors: [tint.opacity(0.18), env.palette.backgroundElevated], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(tint.opacity(0.48), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(accent).tracking(1)
            HStack(spacing: 10) {
                quickAction("Join Discord", "bubble.left.and.bubble.right.fill", Color(red: 0.55, green: 0.48, blue: 1.0), "discord://")
                quickAction("Open PS5", "gamecontroller.fill", Color(red: 0.0, green: 0.42, blue: 1.0), "https://www.playstation.com/en-us/")
                quickAction("Open Xbox", "xbox.logo", env.palette.success, "xbox://")
                quickAction("Start Music", "music.note", accent, "music://")
            }
        }
        .gamingPanel(accent: accent, env: env)
    }

    private func quickAction(_ title: String, _ icon: String, _ tint: Color, _ url: String) -> some View {
        Button {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
            haptic()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 21, weight: .bold)).foregroundStyle(tint).shadow(color: tint.opacity(0.65), radius: 9)
                Text(title).font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(env.palette.textPrimary)
                    .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity).frame(height: 78)
            .background(RoundedRectangle(cornerRadius: 13).fill(LinearGradient(colors: [tint.opacity(0.18), env.palette.backgroundElevated], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(tint.opacity(0.48), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private extension View {
    func gamingPanel(accent: Color, env: ShellEnvironment) -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(env.palette.backgroundElevated)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(accent.opacity(0.4), lineWidth: 0.85))
                    .shadow(color: accent.opacity(0.14), radius: 16, y: 8)
            )
    }
}

// MARK: - Platform connect sheet

private struct GamingPlatformConnectSheet: View {
    let platformName: String
    let accent: Color
    let env: ShellEnvironment
    @Environment(\.dismiss) private var dismiss

    private var platformColor: Color {
        switch platformName {
        case "PS5": return Color(red: 0.0, green: 0.42, blue: 1.0)
        case "XBOX": return env.palette.success
        case "DISCORD": return Color(red: 0.55, green: 0.48, blue: 1.0)
        default: return accent
        }
    }

    private var platformIcon: String {
        switch platformName {
        case "PS5": return "gamecontroller.fill"
        case "XBOX": return "xbox.logo"
        case "DISCORD": return "bubble.left.and.bubble.right.fill"
        default: return "gamecontroller.fill"
        }
    }

    var body: some View {
        ZStack {
            env.palette.background.ignoresSafeArea()
            RadialGradient(colors: [platformColor.opacity(0.2), env.palette.background], center: .top, startRadius: 0, endRadius: 400)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(platformColor.opacity(0.14)).frame(width: 88, height: 88)
                    Image(systemName: platformIcon).font(.system(size: 36, weight: .light)).foregroundColor(platformColor).shadow(color: platformColor.opacity(0.6), radius: 14)
                }
                VStack(spacing: 10) {
                    Text("CONNECT \(platformName)").font(.system(size: 22, weight: .black, design: .monospaced)).foregroundColor(env.palette.textPrimary).tracking(2)
                    Text("Connect your \(platformName) account to surface your game library, achievements, and squad activity.")
                        .font(.system(size: 14)).foregroundColor(env.palette.textSecondary).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 8)
                }
                HStack {
                    Image(systemName: "clock.badge.fill").foregroundColor(platformColor)
                    Text("Platform connections activate when the brain is connected").font(.system(size: 13)).foregroundColor(env.palette.textPrimary)
                    Spacer()
                }
                .padding(16)
                .background(env.palette.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(platformColor.opacity(0.3), lineWidth: 1))

                Button { dismiss() } label: {
                    Text("GOT IT").font(.system(size: 13, weight: .bold, design: .monospaced)).tracking(3).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(platformColor).clipShape(RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }
}
