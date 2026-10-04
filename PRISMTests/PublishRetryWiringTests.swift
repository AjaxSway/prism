import XCTest
@testable import PRISM

/// Proves the per-account retry safety is WIRED through dispatchDetailed(excluding:)
/// — not just an orphaned helper. A retry must not re-send to accounts that
/// already published, and newly-succeeded accounts are reported for persistence.
@MainActor
final class PublishRetryWiringTests: XCTestCase {

    private final class FakeChannels: DispatcherChannelSource {
        var accountsByPlatform: [Platform: [String]] = [:]
        func accountIds(for platforms: [Platform]) -> [String] { platforms.flatMap { accountsByPlatform[$0] ?? [] } }
        func connection(for platform: Platform) -> PlatformConnection { PlatformConnection(platform: platform, isConnected: false) }
        func isConnected(_ platform: Platform) -> Bool { !(accountsByPlatform[platform] ?? []).isEmpty }
    }

    private func res(_ id: String, _ p: String, success: Bool, url: String? = nil, error: String? = nil) -> GatewayPublishResult {
        var o: [String: Any] = ["account_id": id, "platform": p, "success": success]
        if let url { o["post_url"] = url }; if let error { o["error"] = error }
        return try! JSONDecoder().decode(GatewayPublishResult.self, from: try! JSONSerialization.data(withJSONObject: o))
    }
    private func post(_ ps: [Platform]) -> QueuedPost { QueuedPost(content: "hi", platforms: ps, sourcePrompt: "", status: .approved) }

    // First attempt: acct-a succeeds, acct-b fails. Retry must send ONLY acct-b.
    func testRetryExcludesAlreadySucceededAccount() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a", "acct-b"]

        var sentAccounts: [[String]] = []
        func publish(allowSuccess: Set<String>) -> NativePlatformDispatcher.GatewayPublish {
            { _, ids, _ in
                sentAccounts.append(ids)
                return ids.map { self.res($0, "x", success: allowSuccess.contains($0),
                                          url: allowSuccess.contains($0) ? "https://x.com/\($0)" : nil,
                                          error: allowSuccess.contains($0) ? nil : "temporary") }
            }
        }

        // Attempt 1 — only acct-a succeeds.
        let d1 = NativePlatformDispatcher(channels: ch, gatewayPublish: publish(allowSuccess: ["acct-a"]),
                                          blueskyPublish: { _, _, _ in "x" })
        let r1 = await d1.dispatchDetailed(post([.x]))
        XCTAssertEqual(r1.newlySucceededAccountIds, ["acct-a"])
        XCTAssertEqual(sentAccounts.first, ["acct-a", "acct-b"], "attempt 1 sends both")

        // Attempt 2 (retry) — exclude the already-succeeded acct-a.
        let d2 = NativePlatformDispatcher(channels: ch, gatewayPublish: publish(allowSuccess: ["acct-b"]),
                                          blueskyPublish: { _, _, _ in "x" })
        let r2 = await d2.dispatchDetailed(post([.x]), excludingAccountIds: ["acct-a"])
        XCTAssertEqual(sentAccounts.last, ["acct-b"], "retry must send ONLY the failed account, never acct-a again")
        XCTAssertEqual(r2.newlySucceededAccountIds, ["acct-b"])
    }

    // If ALL accounts already succeeded, retry sends nothing and reports success.
    func testRetryWithEverythingDoneSendsNothing() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a"]
        var called = false
        let d = NativePlatformDispatcher(channels: ch,
            gatewayPublish: { _, _, _ in called = true; return [] },
            blueskyPublish: { _, _, _ in "x" })
        let r = await d.dispatchDetailed(post([.x]), excludingAccountIds: ["acct-a"])
        XCTAssertFalse(called, "no publish call when everything already succeeded")
        XCTAssertTrue(r.platformResults[.x]?.isSuccess ?? false)
    }

    // Persistence survives relaunch: QueuedPost encodes/decodes succeededAccountIds.
    func testSucceededAccountsPersistThroughCodable() throws {
        var p = post([.x]); p.succeededAccountIds = ["acct-a", "acct-b"]
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(QueuedPost.self, from: data)
        XCTAssertEqual(Set(decoded.succeededAccountIds), ["acct-a", "acct-b"])
    }

    // Backward compat: old persisted posts without the field decode cleanly.
    func testLegacyPostDecodesWithoutSucceededField() throws {
        let legacy = """
        {"id":"\(UUID().uuidString)","content":"x","platforms":["X"],"sourcePrompt":"",
         "status":"APPROVED","createdAt":0}
        """
        let decoded = try JSONDecoder().decode(QueuedPost.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.succeededAccountIds, [])
    }
}
