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
            .padding(.bottom, 180)
        }
        .background(Color.black)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            env.config.appKind == .prism ? "prism-module-open-\(module.id)" : "module-open-\(module.id)"
        )
    }

    @ViewBuilder
    private func prismModule(_ module: ShellModuleDefinition) -> some View {
        switch module.id {
        case "signal_composer": PrismSignalComposerModuleView(env: env)
        case "platform_outputs": PrismPlatformOutputsView(env: env)
        case "refraction_preview": PrismRefractionPreviewModuleView(env: env)
        case "campaign_calendar": PrismCampaignCalendarView(env: env)
        case "brand_voice": PrismBrandVoiceView(env: env)
        case "draft_queue": PrismDraftQueueView(env: env)
        case "distribution_status": PrismDistributionStatusView(env: env)
        case "proof_assets": PrismProofAssetsView(env: env)
        case "approval_gate": PrismApprovalGateView(env: env)
        case "audience_selector": PrismAudienceSelectorView(env: env)
        case "audit_trail": PrismAuditTrailView(env: env)
        case "image_studio": PrismImageStudioModuleView(env: env)
        default:
            if env.config.appKind == .prism {
                PrismSignalComposerModuleView(env: env)
            } else {
                ShellModulePreviewTemplate(module: module, env: env)
            }
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
        let isPrism = env.config.appKind == .prism
        VStack(spacing: 16) {
            ShellStatusBadge(
                text: isPrism ? "Draft-only · Not connected" : "Shell Preview · Not connected",
                palette: palette
            )
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(module.title, systemImage: module.icon)
                        .font(palette.bodyFont.weight(.semibold))
                        .foregroundColor(palette.textPrimary)
                    Text(module.subtitle)
                        .font(palette.captionFont)
                        .foregroundColor(palette.textSecondary)
                    Text(isPrism
                         ? "This module is not wired in this build. Use the draft studio modules on the home and Modules tab."
                         : "Connect later · Brain connects after operator approval.")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                }
            }
            ShellAuditStrip(
                palette: palette,
                line: isPrism
                    ? "\(module.title) · Draft-only · Approval required · No live publish"
                    : "\(module.title) · Preview · No live services"
            )
            if isPrism {
                ShellPrimaryButton(title: "Open Modules", palette: palette) {
                    env.selectedTab = .modules
                }
            } else {
                HStack(spacing: 10) {
                    ShellPrimaryButton(title: "Preview Module", palette: palette) {
                        env.demoOrbCycle()
                        env.showToast("Module staged", detail: "\(module.title) · shell preview", tone: .action)
                    }
                    Button {
                        env.presentConnectLater(module.title, detail: module.subtitle)
                    } label: {
                        Text("CONNECT PATH")
                            .font(palette.captionFont)
                            .tracking(1)
                            .foregroundColor(palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.accent.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(ShellPressableButtonStyle())
                }
            }
        }
    }
}

// MARK: - PRISM Image Studio module (opens Studio tab)

struct PrismImageStudioModuleView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Image Studio", "Local canvas · preset drafts · draft-only", palette: palette, accent: violet)
            ShellStatusBadge(text: "Draft-only · Not connected", palette: palette, tone: .warning)
            ShellGlassPanel(palette: palette) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Generate preset-based image drafts on device. Gallery saves locally. Share exports approved visuals — no cloud render in this build.")
                        .font(.system(size: 11))
                        .foregroundColor(palette.textSecondary)
                    Text("\(env.draftStore.imageAssets.count) image draft\(env.draftStore.imageAssets.count == 1 ? "" : "s") saved")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(violet)
                }
            }
            ShellPrimaryButton(title: "Open Image Studio", palette: palette) {
                env.selectedTab = .studio
                env.activityStore.append(title: "Image Studio opened", detail: "Studio tab · local drafts", kind: .navigation)
            }
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
                    Text("Audience: \(env.draftStore.selectedAudience) · Saved on device")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textSecondary)
                }
            }
            ShellPrimaryButton(title: "Save Draft", palette: palette) {
                guard !signal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                _ = env.draftStore.saveComposerDraft(sourceText: signal)
                env.showToast("Signal saved", detail: "Open Draft Queue to review", tone: .success)
                env.activityStore.append(title: "Signal saved", detail: signal.prefix(80).description, kind: .info)
            }
        }
        .onAppear {
            if signal.isEmpty, let latest = env.draftStore.latestDraft {
                signal = latest.sourceText
            }
        }
    }
}

struct PrismPlatformOutputsView: View {
    @Bindable var env: ShellEnvironment
    @State private var selectedDraft: PrismSignalDraft?

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        let draft = selectedDraft ?? env.draftStore.latestDraft
        VStack(spacing: 14) {
            moduleHeader("Platform Outputs", "Refraction Preview · \(MockPrismCatalog.socialAccounts.count) social channels", palette: palette, accent: violet)
            if env.draftStore.drafts.isEmpty {
                ShellEmptyState(
                    palette: palette,
                    title: "No outputs yet",
                    message: "Compose on Home, queue refraction, then return here for channel packs.",
                    icon: "square.stack.3d.up.fill",
                    actionTitle: "Open Signal Home",
                    action: { env.selectedTab = .home }
                )
            } else {
                Picker("Draft", selection: Binding(
                    get: { draft?.id ?? env.draftStore.drafts.first!.id },
                    set: { id in selectedDraft = env.draftStore.drafts.first { $0.id == id } }
                )) {
                    ForEach(env.draftStore.drafts) { d in
                        Text(d.titleLine.prefix(40).description).tag(d.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(violet)

                ForEach(draft?.channelOutputs ?? [], id: \.channelId) { output in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(output.channelName).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                                Spacer()
                                ShellStatusBadge(text: draft?.approvalStatus.label ?? "Draft", palette: palette)
                            }
                            Text(output.refractedText)
                                .font(.system(size: 11))
                                .foregroundColor(palette.textSecondary)
                                .lineLimit(6)
                            Button {
                                env.exportDraftText(output.refractedText, label: "Share \(output.channelName)")
                            } label: {
                                Text("Share draft").font(.system(size: 10, weight: .bold)).foregroundColor(violet)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            Text("Draft-only · No live platform publish in this build")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
    }
}

struct PrismRefractionPreviewModuleView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        let draft = env.draftStore.latestDraft
        VStack(spacing: 14) {
            moduleHeader("Refraction Preview", "One signal · platform-ready outputs", palette: palette, accent: violet)
            if let draft {
                ShellGlassPanel(palette: palette) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SOURCE SIGNAL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(violet.opacity(0.7))
                        Text(draft.sourceText)
                            .font(.system(size: 12))
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(8)
                    }
                }
                ForEach(draft.channelOutputs) { output in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Image(systemName: "arrow.triangle.branch").foregroundColor(violet)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(output.channelName).font(.system(size: 11, weight: .semibold)).foregroundColor(palette.textPrimary)
                                    Text(output.refractedText.prefix(120).description).font(.system(size: 10)).foregroundColor(palette.textSecondary)
                                }
                                Spacer()
                                Text("Draft").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(palette.textSecondary)
                            }
                            Button {
                                env.exportDraftText(output.refractedText, label: "Share \(output.channelName)")
                            } label: {
                                Text("Share draft").font(.system(size: 10, weight: .bold)).foregroundColor(violet)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                ShellEmptyState(
                    palette: palette,
                    title: "No refraction yet",
                    message: "Write a signal on Home and tap Queue Refraction Preview.",
                    icon: "arrow.triangle.branch",
                    actionTitle: "Open Signal Home",
                    action: { env.selectedTab = .home }
                )
            }
            ShellAuditStrip(palette: palette, line: "Refraction Preview · Approval required · No live publishing")
        }
    }
}

struct PrismCampaignCalendarView: View {
    @Bindable var env: ShellEnvironment
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Campaign Calendar", "Local schedule · tap a day to assign latest draft", palette: palette, accent: violet)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(days, id: \.self) { day in
                    let scheduled = env.draftStore.drafts(forWeekday: day)
                    Button {
                        guard let latest = env.draftStore.latestDraft else {
                            env.showToast("No draft", detail: "Save or queue a signal first", tone: .warning)
                            return
                        }
                        env.draftStore.schedule(latest.id, weekday: day)
                        env.showToast("Scheduled", detail: "\(latest.titleLine.prefix(30))… on \(day)", tone: .success)
                    } label: {
                        ShellGlassPanel(palette: palette) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(day).font(.system(size: 11, weight: .bold)).foregroundColor(violet)
                                Text(scheduled.isEmpty ? "Tap to schedule" : "\(scheduled.count) draft\(scheduled.count == 1 ? "" : "s")")
                                    .font(.system(size: 9))
                                    .foregroundColor(palette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        }
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
                }
            }
        }
    }
}

struct PrismBrandVoiceView: View {
    @Bindable var env: ShellEnvironment
    private let tones = ["Executive", "Brand", "Technical", "Human"]

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Brand Voice", "Tone · proof · consistency", palette: palette, accent: violet)
            ForEach(tones, id: \.self) { tone in
                Button {
                    env.draftStore.selectedBrandTone = tone
                    env.showToast("Brand tone", detail: tone, tone: .success)
                } label: {
                    ShellGlassPanel(palette: palette) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tone).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                                Text("Applied to new refractions").font(.system(size: 9)).foregroundColor(palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: env.draftStore.selectedBrandTone == tone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(env.draftStore.selectedBrandTone == tone ? violet : palette.textSecondary)
                        }
                    }
                }
                .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
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
            moduleHeader("Draft Queue", "\(env.draftStore.drafts.count) on device · Approval required", palette: palette, accent: violet)
            if env.draftStore.drafts.isEmpty {
                ShellEmptyState(
                    palette: palette,
                    title: "Queue empty",
                    message: "Save a signal or queue refraction from Home.",
                    icon: "tray.full.fill",
                    actionTitle: "Open Signal Home",
                    action: { env.selectedTab = .home }
                )
            } else {
                ForEach(env.draftStore.drafts) { draft in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.titleLine.prefix(48).description).font(.system(size: 12, weight: .bold)).foregroundColor(palette.textPrimary)
                            Text("\(draft.channelOutputs.count) channels · \(draft.audience) · \(draft.approvalStatus.label)")
                                .font(.system(size: 10)).foregroundColor(palette.textSecondary)
                            ShellStatusBadge(text: draft.approvalStatus.label, palette: palette, tone: draft.approvalStatus == .approved ? .success : .warning)
                            HStack(spacing: 8) {
                                if draft.approvalStatus != .approved {
                                    Button {
                                        env.draftStore.approve(draft.id)
                                        env.showToast("Approved", detail: "Local export enabled · publish rail offline", tone: .success)
                                    } label: {
                                        Text("APPROVE").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundColor(violet)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if let first = draft.channelOutputs.first {
                                    Button {
                                        env.exportDraftText(first.refractedText, label: "Share \(first.channelName)")
                                    } label: {
                                        Text("SHARE").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundColor(palette.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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
        let draft = env.draftStore.latestDraft
        VStack(spacing: 14) {
            moduleHeader("Distribution Status", "Pipeline · channels · publish rail", palette: palette, accent: violet)

            ShellStatusBadge(text: "Not connected · Draft-only · Approval required", palette: palette, tone: .warning)

            ShellHUDBracketPanel(accent: violet) {
                VStack(alignment: .leading, spacing: 10) {
                    statusRow("Source Signal", draft == nil ? "None" : "Staged", palette: palette, accent: draft == nil ? palette.offline : violet)
                    statusRow("Refraction", draft == nil ? "Waiting" : "\(draft!.channelOutputs.count) outputs", palette: palette, accent: violet)
                    statusRow("Approval", draft?.approvalStatus.label ?? "—", palette: palette, accent: palette.warning)
                    statusRow("Publish Rail", "Offline · gated", palette: palette, accent: palette.offline)
                }
            }

            ShellCanonSectionHeader(
                title: "Social Channels",
                subtitle: "All offline · Draft and share locally until OAuth ships",
                accent: violet
            )

            ForEach(MockPrismCatalog.socialAccounts) { account in
                ShellGlassPanel(palette: palette) {
                    HStack(spacing: 10) {
                        Image(systemName: account.icon)
                            .foregroundColor(violet)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                            Text("Not connected").font(.system(size: 10)).foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        Button { env.presentChannelConnect(account) } label: {
                            Text("WHY OFFLINE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(violet)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(violet.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Share approved drafts locally until channels connect.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(palette.textSecondary)
        }
    }

    private func statusRow(_ name: String, _ status: String, palette: ShellThemePalette, accent: Color) -> some View {
        HStack {
            PrismLivingStatusDot(color: accent, active: accent != palette.offline)
            Text(name).font(palette.captionFont).foregroundColor(palette.textPrimary)
            Spacer()
            Text(status).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
        }
    }
}

struct PrismProofAssetsView: View {
    @Bindable var env: ShellEnvironment
    private let assets = ["ShellPresetCortex", "ShellPresetB2TB", "ShellPresetControl", "ShellPresetForge", "ShellPresetEcosystem", "ShellPresetAurion"]

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Proof Assets", "Tap to attach to latest draft", palette: palette, accent: violet)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(assets, id: \.self) { img in
                    Button {
                        env.attachProofAsset(img)
                    } label: {
                        Image(img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(violet.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(ShellPressableButtonStyle(scale: 0.96))
                }
            }
            if let draft = env.draftStore.latestDraft, !draft.proofAssetNames.isEmpty {
                Text("Attached: \(draft.proofAssetNames.joined(separator: ", "))")
                    .font(.system(size: 10))
                    .foregroundColor(palette.textSecondary)
            }
        }
    }
}

struct PrismApprovalGateView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        let pending = env.draftStore.pendingDrafts
        VStack(spacing: 14) {
            moduleHeader("Approval Gate", "Nothing exports without sign-off", palette: palette, accent: violet)
            if pending.isEmpty {
                ShellEmptyState(
                    palette: palette,
                    title: "Nothing pending",
                    message: "Queue a refraction from Home or approve from Draft Queue.",
                    icon: "checkmark.seal.fill",
                    actionTitle: "Open Signal Home",
                    action: { env.selectedTab = .home }
                )
            } else {
                ForEach(pending) { draft in
                    ShellGlassPanel(palette: palette) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(draft.titleLine.prefix(60).description).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                            Text("\(draft.channelOutputs.count) channel outputs · \(draft.approvalStatus.label)")
                                .font(.system(size: 10)).foregroundColor(palette.textSecondary)
                            HStack(spacing: 10) {
                                ShellPrimaryButton(title: "Approve", palette: palette) {
                                    env.draftStore.approve(draft.id)
                                    env.showToast("Approved", detail: "Local export enabled · publish rail offline", tone: .success)
                                    env.activityStore.append(title: "Approved", detail: draft.titleLine.prefix(40).description, kind: .command)
                                }
                                Button {
                                    env.draftStore.reject(draft.id)
                                    env.showToast("Rejected", detail: "Returned to draft queue", tone: .warning)
                                } label: {
                                    Text("REJECT")
                                        .font(palette.captionFont)
                                        .foregroundColor(palette.warning)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PrismAudienceSelectorView: View {
    @Bindable var env: ShellEnvironment
    private let segments = [
        ("Executive", "Executive decision makers"),
        ("Brand", "Brand and marketing voice"),
        ("Technical", "Systems and product depth"),
        ("Public", "General audience"),
        ("Internal", "Team and operators"),
    ]

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Audience Selector", "Routes refraction tone", palette: palette, accent: violet)
            ForEach(segments, id: \.0) { seg in
                Button {
                    env.draftStore.selectedAudience = seg.0
                    env.showToast("Audience", detail: seg.0, tone: .success)
                } label: {
                    ShellGlassPanel(palette: palette) {
                        HStack {
                            Image(systemName: "person.3.fill").foregroundColor(violet.opacity(0.75))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(seg.0).font(palette.bodyFont.weight(.semibold)).foregroundColor(palette.textPrimary)
                                Text(seg.1).font(.system(size: 9)).foregroundColor(palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: env.draftStore.selectedAudience == seg.0 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(env.draftStore.selectedAudience == seg.0 ? violet : palette.textSecondary)
                        }
                    }
                }
                .buttonStyle(ShellPressableButtonStyle(scale: 0.98))
            }
        }
    }
}

struct PrismAuditTrailView: View {
    @Bindable var env: ShellEnvironment

    var body: some View {
        let palette = env.palette
        let violet = env.config.refractionAccent ?? palette.accent
        VStack(spacing: 14) {
            moduleHeader("Audit Trail", "Append-only · stored on device", palette: palette, accent: violet)
            if env.draftStore.auditEntries.isEmpty {
                ShellEmptyState(
                    palette: palette,
                    title: "No events",
                    message: "Actions appear here as you draft and approve.",
                    icon: "list.bullet.rectangle.fill",
                    actionTitle: "Open Signal Home",
                    action: { env.selectedTab = .home }
                )
            } else {
                ForEach(env.draftStore.auditEntries) { e in
                    ShellGlassPanel(palette: palette) {
                        HStack(alignment: .top) {
                            Text(e.timeLabel).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(violet.opacity(0.7))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(e.action).font(palette.bodyFont).foregroundColor(palette.textPrimary)
                                Text(e.detail).font(.system(size: 9, design: .monospaced)).foregroundColor(palette.textSecondary)
                            }
                            Spacer()
                        }
                    }
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
        HStack(spacing: 10) {
            ZStack {
                PrismPulseRing(color: accent, diameter: 28, lineWidth: 1, speed: 0.75)
                Circle().fill(accent.opacity(0.35)).frame(width: 6, height: 6)
            }
            Text(title.uppercased())
                .font(palette.titleFont)
                .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .leading, endPoint: .trailing))
        }
        Text(subtitle)
            .font(.system(size: 11))
            .foregroundColor(palette.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
