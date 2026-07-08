import Foundation

enum PrismApprovalStatus: String, Codable, CaseIterable {
    case draft
    case pendingApproval
    case approved
    case rejected

    var label: String {
        switch self {
        case .draft: return "Draft"
        case .pendingApproval: return "Pending approval"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

struct PrismChannelOutput: Codable, Identifiable, Equatable {
    let channelId: String
    let channelName: String
    var refractedText: String

    var id: String { channelId }
}

struct PrismSignalDraft: Codable, Identifiable, Equatable {
    let id: UUID
    var sourceText: String
    var audience: String
    var brandPrinciple: String
    var brandTone: String
    var channelIds: [String]
    var channelOutputs: [PrismChannelOutput]
    var approvalStatus: PrismApprovalStatus
    var scheduledWeekday: String?
    var proofAssetNames: [String]
    let createdAt: Date
    var updatedAt: Date

    var titleLine: String {
        sourceText.split(separator: "\n").first.map(String.init) ?? "Untitled signal"
    }
}

struct PrismAuditEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let action: String
    let detail: String

    var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }
}

struct PrismImageAsset: Codable, Identifiable, Equatable {
    let id: UUID
    let prompt: String
    let presetLabel: String
    let assetImageName: String?
    let createdAt: Date
}

@MainActor
@Observable
final class PrismLocalDraftStore {
    private let storagePrefix: String
    private var draftsKey: String { "\(storagePrefix).drafts.v1" }
    private var auditKey: String { "\(storagePrefix).audit.v1" }
    private var imagesKey: String { "\(storagePrefix).images.v1" }
    private var prefsKey: String { "\(storagePrefix).prefs.v1" }

    private(set) var drafts: [PrismSignalDraft] = []
    private(set) var auditEntries: [PrismAuditEntry] = []
    private(set) var imageAssets: [PrismImageAsset] = []

    var selectedAudience: String = "Executive" {
        didSet { persistPrefs() }
    }
    var selectedBrandTone: String = "Executive" {
        didSet { persistPrefs() }
    }
    var selectedBrandPrinciple: String = MockB2TB.today.principleTitle {
        didSet { persistPrefs() }
    }

    init(storagePrefix: String) {
        self.storagePrefix = storagePrefix
        load()
        seedWelcomeWorkflowIfNeeded()
    }

    /// One-time sample so Approval Gate, Platform Outputs, and Calendar have real local data on first open.
    private func seedWelcomeWorkflowIfNeeded() {
        let key = "\(storagePrefix).welcomeSeeded.v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let text = MockB2TB.samplePost(principle: selectedBrandPrinciple)
        _ = queueRefraction(
            sourceText: text,
            audience: selectedAudience,
            brandPrinciple: selectedBrandPrinciple,
            brandTone: selectedBrandTone,
            channelIds: MockPrismCatalog.socialAccounts.map(\.id)
        )
        _ = saveImageAsset(
            prompt: "PRISM refraction visual · sample draft",
            presetLabel: "Cortex Poster",
            assetImageName: "ShellPresetCortex"
        )
        logAudit("Welcome workflow", detail: "Sample signal + image draft loaded · edit or reset in Settings")
        UserDefaults.standard.set(true, forKey: key)
    }

    var pendingDrafts: [PrismSignalDraft] {
        drafts.filter { $0.approvalStatus == .draft || $0.approvalStatus == .pendingApproval }
    }

    var approvedDrafts: [PrismSignalDraft] {
        drafts.filter { $0.approvalStatus == .approved }
    }

    var latestDraft: PrismSignalDraft? { drafts.first }

    func queueRefraction(
        sourceText: String,
        audience: String,
        brandPrinciple: String,
        brandTone: String,
        channelIds: [String]
    ) -> PrismSignalDraft {
        let outputs = channelIds.compactMap { id -> PrismChannelOutput? in
            guard let account = MockPrismCatalog.accounts.first(where: { $0.id == id }) else { return nil }
            return PrismChannelOutput(
                channelId: id,
                channelName: account.name,
                refractedText: Self.refract(sourceText, channel: account, audience: audience, principle: brandPrinciple)
            )
        }
        let draft = PrismSignalDraft(
            id: UUID(),
            sourceText: sourceText,
            audience: audience,
            brandPrinciple: brandPrinciple,
            brandTone: brandTone,
            channelIds: channelIds,
            channelOutputs: outputs,
            approvalStatus: .pendingApproval,
            scheduledWeekday: nil,
            proofAssetNames: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        drafts.insert(draft, at: 0)
        logAudit("Refraction queued", detail: "\(outputs.count) channels · \(audience) · pending approval")
        persist()
        return draft
    }

    func saveComposerDraft(sourceText: String) -> PrismSignalDraft {
        let draft = PrismSignalDraft(
            id: UUID(),
            sourceText: sourceText,
            audience: selectedAudience,
            brandPrinciple: selectedBrandPrinciple,
            brandTone: selectedBrandTone,
            channelIds: [],
            channelOutputs: [],
            approvalStatus: .draft,
            scheduledWeekday: nil,
            proofAssetNames: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        drafts.insert(draft, at: 0)
        logAudit("Signal saved", detail: sourceText.prefix(80).description)
        persist()
        return draft
    }

    func requestApproval(for draftID: UUID) {
        mutate(draftID) { $0.approvalStatus = .pendingApproval }
        logAudit("Approval requested", detail: draftID.uuidString.prefix(8).description)
    }

    func approve(_ draftID: UUID) {
        mutate(draftID) { $0.approvalStatus = .approved }
        logAudit("Operator approved", detail: "Draft cleared for export · publish rail stays offline")
    }

    func reject(_ draftID: UUID) {
        mutate(draftID) { $0.approvalStatus = .rejected }
        logAudit("Operator rejected", detail: "Draft returned to edit queue")
    }

    func schedule(_ draftID: UUID, weekday: String) {
        mutate(draftID) { $0.scheduledWeekday = weekday }
        logAudit("Schedule set", detail: "\(weekday) · local calendar only")
    }

    func attachProof(_ assetName: String, to draftID: UUID?) {
        let target = draftID ?? drafts.first?.id
        guard let target else { return }
        mutate(target) { draft in
            if !draft.proofAssetNames.contains(assetName) {
                draft.proofAssetNames.append(assetName)
            }
        }
        logAudit("Proof attached", detail: assetName)
    }

    func saveImageAsset(prompt: String, presetLabel: String, assetImageName: String?) -> PrismImageAsset {
        let asset = PrismImageAsset(
            id: UUID(),
            prompt: prompt,
            presetLabel: presetLabel,
            assetImageName: assetImageName,
            createdAt: Date()
        )
        imageAssets.insert(asset, at: 0)
        logAudit("Image staged", detail: presetLabel)
        persist()
        return asset
    }

    func drafts(forWeekday weekday: String) -> [PrismSignalDraft] {
        drafts.filter { $0.scheduledWeekday == weekday }
    }

    func reset() {
        drafts.removeAll()
        auditEntries.removeAll()
        imageAssets.removeAll()
        selectedAudience = "Executive"
        selectedBrandTone = "Executive"
        selectedBrandPrinciple = MockB2TB.today.principleTitle
        UserDefaults.standard.removeObject(forKey: "\(storagePrefix).welcomeSeeded.v2")
        persist()
        seedWelcomeWorkflowIfNeeded()
    }

    func localCommandResponse(for command: String) -> String {
        let lower = command.lowercased()
        if lower.contains("draft signal") || lower.contains("create signal") {
            let text = MockB2TB.samplePost(principle: selectedBrandPrinciple)
            _ = queueRefraction(
                sourceText: text,
                audience: selectedAudience,
                brandPrinciple: selectedBrandPrinciple,
                brandTone: selectedBrandTone,
                channelIds: MockPrismCatalog.socialAccounts.map(\.id)
            )
            return "Staged a sample signal across \(MockPrismCatalog.socialAccounts.count) social channels. Open Draft Queue or Approval Gate to review."
        }
        if lower.contains("approval") {
            if let d = pendingDrafts.first {
                requestApproval(for: d.id)
                return "Moved “\(d.titleLine.prefix(40))…” to pending approval. Open Approval Gate to sign off."
            }
            return "No pending drafts yet. Queue a refraction from home or save a signal first."
        }
        if lower.contains("channel") {
            return "Channel pack uses your refraction outputs. Select channels on home, queue refraction, then open Platform Outputs."
        }
        if lower.contains("schedule") {
            if let d = drafts.first {
                schedule(d.id, weekday: "Mon")
                return "Scheduled latest draft on Monday (local calendar). Open Campaign Calendar to adjust."
            }
            return "Save or queue a signal before scheduling."
        }
        return """
        PRISM draft studio received: \(command.prefix(120))

        Staged locally — no cloud publish. Use home composer to queue refraction, then Approval Gate before export.
        """
    }

    private func mutate(_ id: UUID, _ edit: (inout PrismSignalDraft) -> Void) {
        guard let idx = drafts.firstIndex(where: { $0.id == id }) else { return }
        edit(&drafts[idx])
        drafts[idx].updatedAt = Date()
        persist()
    }

    private func logAudit(_ action: String, detail: String) {
        auditEntries.insert(
            PrismAuditEntry(id: UUID(), timestamp: Date(), action: action, detail: detail),
            at: 0
        )
        if auditEntries.count > 100 { auditEntries.removeLast(auditEntries.count - 100) }
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(drafts) {
            UserDefaults.standard.set(data, forKey: draftsKey)
        }
        if let data = try? encoder.encode(auditEntries) {
            UserDefaults.standard.set(data, forKey: auditKey)
        }
        if let data = try? encoder.encode(imageAssets) {
            UserDefaults.standard.set(data, forKey: imagesKey)
        }
        persistPrefs()
    }

    private func persistPrefs() {
        let prefs: [String: String] = [
            "audience": selectedAudience,
            "tone": selectedBrandTone,
            "principle": selectedBrandPrinciple
        ]
        UserDefaults.standard.set(prefs, forKey: prefsKey)
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = UserDefaults.standard.data(forKey: draftsKey),
           let saved = try? decoder.decode([PrismSignalDraft].self, from: data) {
            drafts = saved
        }
        if let data = UserDefaults.standard.data(forKey: auditKey),
           let saved = try? decoder.decode([PrismAuditEntry].self, from: data) {
            auditEntries = saved
        }
        if let data = UserDefaults.standard.data(forKey: imagesKey),
           let saved = try? decoder.decode([PrismImageAsset].self, from: data) {
            imageAssets = saved
        }
        if let prefs = UserDefaults.standard.dictionary(forKey: prefsKey) as? [String: String] {
            selectedAudience = prefs["audience"] ?? selectedAudience
            selectedBrandTone = prefs["tone"] ?? selectedBrandTone
            selectedBrandPrinciple = prefs["principle"] ?? selectedBrandPrinciple
        }
    }

    static func refract(_ source: String, channel: MockPrismAccount, audience: String, principle: String) -> String {
        let hook = source.split(separator: "\n").first.map(String.init) ?? source
        switch channel.id {
        case "x":
            return String("\(hook.prefix(240)) · #\(principle)").prefix(280).description
        case "ig":
            return "\(hook)\n\n\(audience) voice · \(principle) principle\n#CORTEX #PRISM #\(principle.replacingOccurrences(of: " ", with: ""))"
        case "li":
            return "\(audience) update · \(principle)\n\n\(source.prefix(900))"
        case "yt":
            return "Title: \(hook.prefix(80))\nDescription: \(source.prefix(400))"
        case "tt":
            return "Hook: \(hook.prefix(120))\nCaption: \(source.prefix(300))"
        case "email":
            return "Subject: \(hook.prefix(60))\n\n\(source)"
        default:
            return "[\(channel.name) · \(audience)]\n\(source)"
        }
    }
}
