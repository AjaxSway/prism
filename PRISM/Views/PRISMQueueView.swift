import SwiftUI

struct PRISMQueueView: View {
    @State private var queue = PostingQueue.shared
    @State private var channels = PlatformChannelManager.shared
    @State private var postingId: UUID?
    @State private var errorMessage = ""

    private let v  = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let c  = Color(red: 0.133, green: 0.827, blue: 0.933)
    private let p  = Color(red: 0.925, green: 0.286, blue: 0.600)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("PUBLISH QUEUE")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(v).tracking(4)
                    .shadow(color: v.opacity(0.7), radius: 16)
                Text("Approve · then broadcast only to connected accounts")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
                HStack(spacing: 12) {
                    queueChip("DRAFT",    count: queue.drafts.count,   color: v)
                    queueChip("APPROVED", count: queue.approved.count, color: c)
                    queueChip("POSTED",   count: queue.posted.count,   color: p)
                }
                .padding(.top, 6)
            }
            .padding(.top, 12).padding(.bottom, 14)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, v, c, p, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1).opacity(0.4).padding(.horizontal, 40).padding(.bottom, 14)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 20).padding(.bottom, 8)
                    .multilineTextAlignment(.center)
            }

            if queue.drafts.isEmpty && queue.approved.isEmpty && queue.posted.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(v.opacity(0.3))
                    Text("QUEUE EMPTY")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(v.opacity(0.3)).tracking(3)
                    Text("Draft from Channels → New Draft,\nor approve a Home signal in Modules.\nBroadcast only when accounts are connected.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        if !queue.drafts.isEmpty {
                            sectionHeader("AWAITING APPROVAL", color: v)
                            ForEach(queue.drafts) { post in
                                postRow(post, accent: v)
                            }
                        }
                        if !queue.approved.isEmpty {
                            sectionHeader("APPROVED · REVIEW BEFORE PUBLISH", color: c)
                            ForEach(queue.approved) { post in
                                postRow(post, accent: c)
                            }
                        }
                        if !queue.posted.isEmpty {
                            sectionHeader("POSTED", color: p)
                            ForEach(queue.posted.prefix(5)) { post in
                                postRow(post, accent: p)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await channels.refreshGatewayAccounts()
        }
    }

    private func queueChip(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Text("\(count)")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(color.opacity(0.6)).tracking(1)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 1))
        .cornerRadius(4)
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Rectangle().fill(color.opacity(0.4)).frame(height: 1)
            Text(title)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(color.opacity(0.6)).tracking(2)
                .fixedSize()
            Rectangle().fill(color.opacity(0.4)).frame(height: 1)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func connectedPlatforms(for post: QueuedPost) -> [Platform] {
        post.platforms.filter { channels.isConnected($0) }
    }

    private func postRow(_ post: QueuedPost, accent: Color) -> some View {
        let connected = connectedPlatforms(for: post)
        let isPosting = postingId == post.id

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.platformIcons)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(accent)
                Spacer()
                Text(relativeTime(post.createdAt))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }

            Text(post.content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(3)
                .lineSpacing(3)

            Text("— Posted by CORTEX · cortexnode.ai")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(accent.opacity(0.45))
                .lineLimit(1)

            if post.status == .draft {
                HStack(spacing: 10) {
                    Spacer()
                    Button { queue.reject(post) } label: {
                        Text("REJECT")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.red.opacity(0.7)).tracking(1)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.red.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button { queue.approve(post) } label: {
                        Text("APPROVE")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(accent).tracking(1)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(accent.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent.opacity(0.5), lineWidth: 1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            } else if post.status == .approved {
                HStack {
                    if connected.isEmpty {
                        Text("NOT CONNECTED — connect accounts in Channels")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange.opacity(0.85))
                        Spacer()
                    } else {
                        Text("\(connected.count)/\(post.platforms.count) ready")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(c.opacity(0.7))
                        Spacer()
                        Button {
                            guard !isPosting else { return }
                            Task { await broadcastPost(post) }
                        } label: {
                            HStack(spacing: 6) {
                                if isPosting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.6)
                                        .tint(c)
                                    Text("BROADCASTING...")
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(c.opacity(0.6)).tracking(1)
                                } else {
                                    Image(systemName: "dot.radiowaves.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(c)
                                    Text("BROADCAST NOW")
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(c).tracking(1)
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(c.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(c.opacity(isPosting ? 0.2 : 0.4), lineWidth: 1))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPosting)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(accent.opacity(0.03))
        .contextMenu {
            Button {
                UIPasteboard.general.string = post.content
            } label: {
                Label("Copy Caption", systemImage: "doc.on.doc")
            }
            if post.status == .posted {
                Button(role: .destructive) {
                    queue.remove(post)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func broadcastPost(_ post: QueuedPost) async {
        postingId = post.id
        errorMessage = ""

        let connected = connectedPlatforms(for: post)
        guard !connected.isEmpty else {
            postingId = nil
            errorMessage = "No connected accounts for this draft. Connect in Channels first."
            return
        }

        // Only dispatch to connected platforms — never claim success for skipped ones.
        let scoped = QueuedPost(
            content: post.content,
            platforms: connected,
            sourcePrompt: post.sourcePrompt,
            status: .approved
        )
        // Preserve identity for markPosted by using original post after success
        let results = await NativePlatformDispatcher.shared.dispatch(scoped)

        postingId = nil

        let successes = results.filter { $0.value.isSuccess }
        let failures = results.filter {
            if case .skipped = $0.value { return false }
            return !$0.value.isSuccess
        }

        if !successes.isEmpty && failures.isEmpty {
            queue.markPosted(post)
            errorMessage = ""
        } else if !successes.isEmpty {
            queue.markPosted(post)
            let platformNames = failures.keys.map(\.rawValue).joined(separator: ", ")
            let reason = failures.values.first.map(\.label) ?? "partial failure"
            errorMessage = "Posted some · issues on \(platformNames): \(reason)"
        } else {
            let platformNames = results.keys.map(\.rawValue).joined(separator: ", ")
            let reason = results.values.first.map(\.label) ?? "Unknown error"
            errorMessage = "Not posted · \(platformNames): \(reason)"
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = Int(-date.timeIntervalSinceNow)
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(diff/60)m ago" }
        if diff < 86400 { return "\(diff/3600)h ago" }
        return "\(diff/86400)d ago"
    }
}
