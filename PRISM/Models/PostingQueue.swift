import Foundation

// MARK: - PRISM Posting Queue
// Holds drafted posts awaiting operator approval.
// Nothing leaves this queue without explicit approval — rule is hardcoded.

@MainActor
@Observable
final class PostingQueue {
    static let shared = PostingQueue()

    var drafts: [QueuedPost] = []
    var approved: [QueuedPost] = []
    var posted: [QueuedPost] = []

    private let draftsKey = "prism_queue_drafts"
    private let approvedKey = "prism_queue_approved"
    private let postedKey = "prism_queue_posted"
    private init() { load() }

    func addDraft(content: String, platforms: [Platform], sourcePrompt: String) {
        let post = QueuedPost(
            content: content,
            platforms: platforms,
            sourcePrompt: sourcePrompt,
            status: .draft
        )
        drafts.insert(post, at: 0)
        save()
    }

    /// Sync an approved Modules/Home draft into the publish queue (approved lane).
    @discardableResult
    func enqueueApprovedFromStudio(content: String, channelIds: [String], sourcePrompt: String) -> QueuedPost? {
        let platforms = channelIds.compactMap { Platform.fromChannelId($0) }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard !platforms.isEmpty else { return nil }
        // Dedupe: same content already waiting to broadcast
        if approved.contains(where: { $0.content == content }) { return approved.first(where: { $0.content == content }) }
        var post = QueuedPost(
            content: content,
            platforms: platforms,
            sourcePrompt: sourcePrompt,
            status: .approved
        )
        post.approvedAt = Date()
        approved.insert(post, at: 0)
        save()
        return post
    }

    func approve(_ post: QueuedPost) {
        drafts.removeAll { $0.id == post.id }
        var updated = post
        updated.status = .approved
        updated.approvedAt = Date()
        approved.insert(updated, at: 0)
        save()
    }

    func reject(_ post: QueuedPost) {
        drafts.removeAll { $0.id == post.id }
        save()
    }

    /// Persist which gateway accounts have already published for this post, so a
    /// retry excludes them (survives relaunch via save()). Merges, never drops.
    func recordSucceededAccounts(_ post: QueuedPost, accountIds: [String]) {
        func merge(_ arr: inout [QueuedPost]) {
            if let i = arr.firstIndex(where: { $0.id == post.id }) {
                var updated = arr[i]
                updated.succeededAccountIds = Array(Set(updated.succeededAccountIds).union(accountIds))
                arr[i] = updated
            }
        }
        merge(&approved); merge(&drafts); merge(&posted)
        save()
    }

    func markPosted(_ post: QueuedPost) {        approved.removeAll { $0.id == post.id }
        var updated = post
        updated.status = .posted
        updated.postedAt = Date()
        posted.insert(updated, at: 0)
        save()
    }

    func remove(_ post: QueuedPost) {
        drafts.removeAll   { $0.id == post.id }
        approved.removeAll { $0.id == post.id }
        posted.removeAll   { $0.id == post.id }
        save()
    }

    var pendingCount: Int { drafts.count }

    private func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(drafts) { defaults.set(data, forKey: draftsKey) }
        if let data = try? JSONEncoder().encode(approved) { defaults.set(data, forKey: approvedKey) }
        if let data = try? JSONEncoder().encode(posted) { defaults.set(data, forKey: postedKey) }
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: draftsKey),
           let saved = try? JSONDecoder().decode([QueuedPost].self, from: data) {
            drafts = saved
        }
        if let data = defaults.data(forKey: approvedKey),
           let saved = try? JSONDecoder().decode([QueuedPost].self, from: data) {
            approved = saved
        }
        if let data = defaults.data(forKey: postedKey),
           let saved = try? JSONDecoder().decode([QueuedPost].self, from: data) {
            posted = saved
        }
    }
}

struct QueuedPost: Identifiable, Codable {
    let id: UUID
    let content: String
    let platforms: [Platform]
    let sourcePrompt: String
    var status: PostStatus
    let createdAt: Date
    var approvedAt: Date?
    var postedAt: Date?
    /// Gateway account IDs that have ALREADY published successfully (or were
    /// accepted) for this post. A retry MUST NOT re-send to these — prevents
    /// double-posting. Persisted so the guarantee survives app relaunch.
    var succeededAccountIds: [String] = []

    init(content: String, platforms: [Platform], sourcePrompt: String, status: PostStatus) {
        self.id = UUID()
        self.content = content
        self.platforms = platforms
        self.sourcePrompt = sourcePrompt
        self.status = status
        self.createdAt = Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, content, platforms, sourcePrompt, status, createdAt, approvedAt, postedAt, succeededAccountIds
    }

    // Decodes older persisted posts that lack succeededAccountIds.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        content = try c.decode(String.self, forKey: .content)
        platforms = try c.decode([Platform].self, forKey: .platforms)
        sourcePrompt = try c.decode(String.self, forKey: .sourcePrompt)
        status = try c.decode(PostStatus.self, forKey: .status)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        approvedAt = try c.decodeIfPresent(Date.self, forKey: .approvedAt)
        postedAt = try c.decodeIfPresent(Date.self, forKey: .postedAt)
        succeededAccountIds = try c.decodeIfPresent([String].self, forKey: .succeededAccountIds) ?? []
    }

    var platformIcons: String {
        platforms.map(\.rawValue).joined(separator: " · ")
    }
}

enum PostStatus: String, Codable {
    case draft = "DRAFT"
    case approved = "APPROVED"
    case posted = "POSTED"
}

enum Platform: String, Codable, CaseIterable {
    case x = "X"
    case instagram = "IG"
    case tiktok = "TIKTOK"
    case linkedin = "LI"
    case bluesky = "BSKY"
    case threads = "THREADS"
    case facebook = "FB"
    case youtube = "YT"

    var icon: String {
        switch self {
        case .x:         return "dot.radiowaves.left.and.right"
        case .instagram: return "camera.circle.fill"
        case .tiktok:    return "music.note.tv.fill"
        case .linkedin:  return "person.crop.circle.fill"
        case .bluesky:   return "cloud.circle.fill"
        case .threads:   return "bubble.circle.fill"
        case .facebook:  return "f.circle.fill"
        case .youtube:   return "play.rectangle.fill"
        }
    }

    /// Human-readable platform name for user-facing status messages.
    var displayName: String {
        switch self {
        case .x:         return "X"
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        case .linkedin:  return "LinkedIn"
        case .bluesky:   return "Bluesky"
        case .threads:   return "Threads"
        case .facebook:  return "Facebook"
        case .youtube:   return "YouTube"
        }
    }

    /// Maps MockPrismCatalog / studio channel ids → Platform.
    static func fromChannelId(_ id: String) -> Platform? {
        switch id.lowercased() {
        case "x", "twitter": return .x
        case "ig", "instagram": return .instagram
        case "li", "linkedin": return .linkedin
        case "fb", "facebook": return .facebook
        case "threads": return .threads
        case "bluesky", "bsky": return .bluesky
        case "yt", "youtube": return .youtube
        case "tt", "tiktok": return .tiktok
        default: return nil
        }
    }
}
