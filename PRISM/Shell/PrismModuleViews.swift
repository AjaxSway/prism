import SwiftUI

// MARK: - Module detail router

struct ShellModuleDetailView: View {
    let module: ShellModuleDefinition
    @Bindable var env: ShellEnvironment

    var body: some View {
        ScrollView(showsIndicators: false) {
            Group {
                switch env.config.appKind {
                case .prism:
                    prismModule(module)
                case .jericho:
                    jerichoModule(module)
                case .cortexNode:
                    nodeModule(module)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.black)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func prismModule(_ module: ShellModuleDefinition) -> some View {
        switch module.id {
        case "signal_composer": PrismSignalComposerModuleView(env: env)
        case "platform_outputs": PrismPlatformOutputsView(env: env)
        case "campaign_calendar": PrismCampaignCalendarView(env: env)
        case "brand_voice": PrismBrandVoiceView(env: env)
        case "draft_queue": PrismDraftQueueView(env: env)
        case "distribution_status": PrismDistributionStatusView(env: env)
        case "proof_assets": PrismProofAssetsView(env: env)
        case "approval_gate": PrismApprovalGateView(env: env)
        default: ShellModulePreviewTemplate(module: module, env: env)
        }
    }

    @ViewBuilder
    private func jerichoModule(_ module: ShellModuleDefinition) -> some View {
        switch module.id {
        case "trust_check": JerichoTrustCheckView(env: env)
        case "permission_gate": JerichoPermissionGateView(env: env)
        case "boundary_rules": JerichoBoundaryRulesView(env: env)
        case "audit_trail": JerichoAuditTrailView(env: env)
        case "risk_review": JerichoRiskReviewView(env: env)
        case "policy_guardrail": JerichoPolicyGuardrailView(env: env)
        case "integrity_scan": JerichoIntegrityScanView(env: env)
        case "alert_review": JerichoAlertReviewView(env: env)
        default: ShellModulePreviewTemplate(module: module, env: env)
        }
    }

    @ViewBuilder
    private func nodeModule(_ module: ShellModuleDefinition) -> some View {
        switch module.id {
        case "system_map": NodeSystemMapView(env: env)
        case "node_health": NodeHealthView(env: env)
        case "connected_apps": NodeConnectedAppsView(env: env)
        case "data_flow": NodeDataFlowView(env: env)
        case "device_links": NodeDeviceLinksView(env: env)
        case "ecosystem_overview": NodeEcosystemOverviewView(env: env)
        case "account_surface": NodeAccountSurfaceView(env: env)
        case "sync_status": NodeSyncStatusView(env: env)
        default: ShellModulePreviewTemplate(module: module, env: env)
        }
    }
}

// MARK: - Generic preview shell

struct ShellModulePreviewTemplate: View {
    let module: ShellModuleDefinition
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        VStack(spacing: 16) {
            ShellStatusBadge(text: "Shell Preview · Not connected", palette: palette)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(module.title, systemImage: module.icon)
                        .font(palette.bodyFont.weight(.semibold))
                        .foregroundColor(palette.textPrimary)
                    Text(module.subtitle)
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    Text("Connect later · Claude wires brain after approval.")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                }
            }
            ShellAuditStrip(palette: palette, line: "\(module.title) · Mock-only · No live services")
        }
    }
}

// MARK: - PRISM modules

struct PrismSignalComposerModuleView: View {
    @Bindable var env: ShellEnvironment
    @State private var signal = ""

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Create Signal", "Source Signal · Draft-only", palette: palette, accent: violet)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("SOURCE SIGNAL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(violet.opacity(0.7))
                    TextField("One approved message · one voice…", text: $signal, axis: .vertical)
                        .lineLimit(4...8)
                        .foregroundColor(palette.textPrimary)
                    Text("Approval required before refraction.")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                }
            }
            ShellPrimaryButton(title: "Save Draft (Preview)", palette: palette) {}
        }
    }
}

struct PrismPlatformOutputsView: View {
    @Bindable var env: ShellEnvironment

    private let channels = ["X", "Instagram", "LinkedIn", "Bluesky", "TikTok", "Threads", "YouTube", "Facebook"]

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Platform Outputs", "Refraction Preview · 8 channels", palette: palette, accent: violet)
            ForEach(channels, id: \.self) { ch in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Text(ch).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                        Spacer()
                        ShellStatusBadge(text: "Draft-only", palette: palette)
                    }
                }
            }
            Text("No live publishing · Connect later")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
    }
}

struct PrismCampaignCalendarView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Campaign Calendar", "Schedule preview · Mock dates", palette: palette, accent: violet)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day).font(.system(size: 11, weight: .bold)).foregroundColor(violet)
                            Text("No drafts").font(.system(size: 9)).foregroundColor(palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    }
                }
            }
        }
    }
}

struct PrismBrandVoiceView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Brand Voice", "Tone · proof · consistency", palette: palette, accent: violet)
            ForEach(["Executive", "Founder", "Technical", "Human"], id: \.self) { tone in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tone).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                            Text("Mock profile · Connect later").font(.system(size: 9)).foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        Circle().stroke(violet.opacity(0.4), lineWidth: 1).frame(width: 18, height: 18)
                    }
                }
            }
        }
    }
}

struct PrismDraftQueueView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Draft Queue", "Approval required · No live publish", palette: palette, accent: violet)
            ForEach(0..<3, id: \.self) { i in
                ShellGlassPanel(palette: palette) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Draft #\(i + 1)").font(.system(size: 12, weight: .bold)).foregroundColor(palette.textPrimary)
                        Text("Refraction preview · awaiting approval").font(.system(size: 10)).foregroundColor(palette.textSecondary)
                        ShellStatusBadge(text: "Draft-only", palette: palette)
                    }
                }
            }
        }
    }
}

struct PrismDistributionStatusView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Distribution Status", "Platform-ready outputs · offline", palette: palette, accent: violet)
            ShellHUDBracketPanel(accent: violet) {
                VStack(alignment: .leading, spacing: 10) {
                    statusRow("Source Signal", "Staged", palette: palette, accent: violet)
                    statusRow("Refraction", "Not connected", palette: palette, accent: palette.offline)
                    statusRow("Publish Rail", "Gated", palette: palette, accent: palette.warning)
                }
            }
        }
    }

    private func statusRow(_ name: String, _ status: String, palette: ShellThemePalette, accent: Color) -> some View {
        HStack {
            Circle().fill(accent).frame(width: 6, height: 6)
            Text(name).font(palette.captionFont).foregroundColor(palette.textPrimary)
            Spacer()
            Text(status).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
        }
    }
}

struct PrismProofAssetsView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Proof Assets", "Screenshots · receipts · audit line", palette: palette, accent: violet)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(["ShellPresetCortex", "ShellPresetB2TB", "ShellPresetControl"], id: \.self) { img in
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(violet.opacity(0.3), lineWidth: 1))
                }
            }
            Text("Proof assets attach to approved signals · Mock gallery")
                .font(.system(size: 10))
                .foregroundColor(palette.textSecondary)
        }
    }
}

struct PrismApprovalGateView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Approval Gate", "Nothing posts without sign-off", palette: palette, accent: violet)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Operator sign-off required before any platform output leaves PRISM.")
                        .font(palette.bodyFont)
                        .foregroundColor(palette.textPrimary)
                    ShellPrimaryButton(title: "Approve (Disabled)", palette: palette) {}
                }
            }
        }
    }
}

// MARK: - JERICHO trust modules (distinct surfaces)

struct JerichoTrustCheckView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        VStack(spacing: 14) {
            moduleHeader("Trust State", "Score + proof summary · Advisory preview", palette: palette, accent: red)
            ShellGlassPanel(palette: palette) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRUST INDEX").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(palette.textSecondary)
                        Text("—").font(.system(size: 36, weight: .black, design: .monospaced)).foregroundColor(red.opacity(0.5))
                        Text("Not connected · Preview only").font(.system(size: 10)).foregroundColor(palette.textSecondary)
                    }
                    Spacer()
                    ShellStatusBadge(text: "Shell Preview", palette: palette)
                }
            }
            ForEach(["Policy registry", "Approval posture", "Audit coverage"], id: \.self) { proof in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Text(proof).font(.system(size: 11)).foregroundColor(palette.textPrimary)
                        Spacer()
                        Text("No proof yet").font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                    }
                }
            }
            ShellAuditStrip(palette: palette, line: "Advisory only · Not a compliance guarantee")
        }
    }
}

struct JerichoPermissionGateView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        let gates = [("Publish", "Locked"), ("Sync", "Locked"), ("Deploy", "Locked"), ("Export", "Preview")]
        VStack(spacing: 14) {
            moduleHeader("Permission Gate", "Approval matrix · Shell preview", palette: palette, accent: red)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(gates, id: \.0) { gate in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(gate.0.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(palette.textPrimary)
                            HStack {
                                Image(systemName: gate.1 == "Locked" ? "lock.fill" : "eye.fill").foregroundColor(red.opacity(0.7))
                                Text(gate.1).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    }
                }
            }
            Text("Approval required before any protected action · Connect later")
                .font(.system(size: 10)).foregroundColor(palette.textSecondary)
        }
    }
}

struct JerichoBoundaryRulesView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        let rules = [
            ("Credential firewall", "Locked policy"),
            ("No secrets in chat", "Locked policy"),
            ("Triad dispatch for risky actions", "Preview"),
            ("Operator sign-off required", "Locked policy")
        ]
        VStack(spacing: 14) {
            moduleHeader("Boundary Rules", "Locked policies · Connect later", palette: palette, accent: red)
            ForEach(rules, id: \.0) { rule in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Image(systemName: rule.1.contains("Locked") ? "lock.fill" : "doc.text").foregroundColor(red.opacity(0.65))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.0).font(.system(size: 11, weight: .semibold)).foregroundColor(palette.textPrimary)
                            Text(rule.1).font(.system(size: 9)).foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

struct JerichoAuditTrailView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        let entries = [
            ("13:46:02", "Trust check opened", "Mock"),
            ("13:45:58", "Boundary rule viewed", "Mock"),
            ("13:45:41", "Permission gate preview", "Mock")
        ]
        VStack(spacing: 14) {
            moduleHeader("Audit Trail", "Immutable proof language · Offline preview", palette: palette, accent: red)
            ShellAuditStrip(palette: palette, line: "Append-only ledger · Connect later for live audit sync")
            ForEach(entries, id: \.0) { entry in
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        Circle().fill(red.opacity(0.6)).frame(width: 8, height: 8)
                        Rectangle().fill(red.opacity(0.2)).frame(width: 1, height: 36)
                    }
                    ShellGlassPanel(palette: palette) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.1).font(.system(size: 11)).foregroundColor(palette.textPrimary)
                                Text(entry.0).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                            }
                            Spacer()
                            Text(entry.2).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

struct JerichoRiskReviewView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        let risks: [(String, String, Color)] = [
            ("Publish without approval", "Medium", Color(red: 0.98, green: 0.68, blue: 0.12)),
            ("Unverified connector", "Low", palette.textSecondary),
            ("Policy drift", "Preview", red.opacity(0.6))
        ]
        VStack(spacing: 14) {
            moduleHeader("Risk Review", "Severity chips · Advisory scoring", palette: palette, accent: red)
            ForEach(risks, id: \.0) { risk in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Text(risk.0).font(.system(size: 11)).foregroundColor(palette.textPrimary)
                        Spacer()
                        Text(risk.1.uppercased())
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(risk.2.opacity(0.85)))
                    }
                }
            }
            ShellAuditStrip(palette: palette, line: "Advisory scoring only · Not a security guarantee")
        }
    }
}

struct JerichoPolicyGuardrailView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        VStack(spacing: 14) {
            moduleHeader("Policy Guardrail", "Governance rules · Connect later", palette: palette, accent: red)
            ForEach(["No publish without approval", "No secrets in chat or logs", "Credential firewall enforced", "Triad dispatch for risky actions"], id: \.self) { rule in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Image(systemName: "doc.text.fill").foregroundColor(red.opacity(0.7))
                        Text(rule).font(.system(size: 11)).foregroundColor(palette.textPrimary)
                        Spacer()
                        ShellStatusBadge(text: "Preview", palette: palette)
                    }
                }
            }
            ShellAuditStrip(palette: palette, line: "Advisory guardrails · Not legal advice")
        }
    }
}

struct JerichoIntegrityScanView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        VStack(spacing: 14) {
            moduleHeader("Integrity Scan", "Mock checklist · No live device scan", palette: palette, accent: red)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    checklistRow("Shell bundle integrity", checked: true, palette: palette)
                    checklistRow("Brain gateway wiring", checked: false, palette: palette)
                    checklistRow("Policy registry sync", checked: false, palette: palette)
                    checklistRow("Operator approval path", checked: false, palette: palette)
                }
            }
            Text("No antivirus claims · Connect later for live integrity checks")
                .font(.system(size: 10))
                .foregroundColor(palette.textSecondary)
        }
    }

    private func checklistRow(_ name: String, checked: Bool, palette: ShellThemePalette) -> some View {
        HStack {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .foregroundColor(checked ? palette.accent : palette.offline)
            Text(name).font(palette.captionFont).foregroundColor(palette.textPrimary)
            Spacer()
            Text(checked ? "Preview" : "Pending").font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
        }
    }

    private func scanRow(_ name: String, _ status: String, palette: ShellThemePalette) -> some View {
        HStack {
            Circle().fill(palette.offline).frame(width: 6, height: 6)
            Text(name).font(palette.captionFont).foregroundColor(palette.textPrimary)
            Spacer()
            Text(status).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
        }
    }
}

struct JerichoAlertReviewView: View {
    @Bindable var env: ShellEnvironment
    var body: some View {
        let palette = env.palette
        let red = env.config.accent
        let alerts = [
            ("Policy review queued", "Preview", false),
            ("Boundary rule draft", "Preview", false),
            ("Operator sign-off pending", "Approval", true)
        ]
        VStack(spacing: 14) {
            moduleHeader("Alert Review", "Alert queue preview · Not connected", palette: palette, accent: red)
            ForEach(alerts, id: \.0) { alert in
                ShellGlassPanel(palette: palette) {
                    HStack {
                        Image(systemName: alert.2 ? "exclamationmark.circle.fill" : "bell.badge.fill")
                            .foregroundColor(alert.2 ? Color(red: 0.98, green: 0.68, blue: 0.12) : red.opacity(0.6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.0).font(.system(size: 11)).foregroundColor(palette.textPrimary)
                            Text(alert.1).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        ShellStatusBadge(text: "Mock", palette: palette)
                    }
                }
            }
            Text("No device alerts · Governance queue only · Connect later")
                .font(.system(size: 10)).foregroundColor(palette.textSecondary)
        }
    }
}

private func moduleHeader(_ title: String, _ subtitle: String, palette: ShellThemePalette, accent: Color) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title.uppercased())
            .font(palette.titleFont)
            .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .leading, endPoint: .trailing))
        Text(subtitle)
            .font(.system(size: 11))
            .foregroundColor(palette.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
