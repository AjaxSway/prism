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

    private let storageKey = "prism_queue_drafts"
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

    func markPosted(_ post: QueuedPost) {
        approved.removeAll { $0.id == post.id }
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
        if let data = try? JSONEncoder().encode(drafts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([QueuedPost].self, from: data) {
            drafts = saved
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

    init(content: String, platforms: [Platform], sourcePrompt: String, status: PostStatus) {
        self.id = UUID()
        self.content = content
        self.platforms = platforms
        self.sourcePrompt = sourcePrompt
        self.status = status
        self.createdAt = Date()
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
}
