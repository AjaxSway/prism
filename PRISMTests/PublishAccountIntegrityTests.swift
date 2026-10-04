import XCTest
@testable import PRISM

/// Account-level publishing correctness that the platform-only classifier did
/// not cover: exact requested-account matching, missing/duplicate results,
/// multiple accounts on one platform, and provider post-ID (not just URL)
/// receipts. Exercises the real dispatch() path via injected fakes — no network.
@MainActor
final class PublishAccountIntegrityTests: XCTestCase {

    private final class FakeChannels: DispatcherChannelSource {
        var accountsByPlatform: [Platform: [String]] = [:]
        var blueskyConnected = false
        func accountIds(for platforms: [Platform]) -> [String] {
            platforms.flatMap { accountsByPlatform[$0] ?? [] }
        }
        func connection(for platform: Platform) -> PlatformConnection {
            PlatformConnection(platform: platform, isConnected: platform == .bluesky ? blueskyConnected : false)
        }
        func isConnected(_ platform: Platform) -> Bool {
            if platform == .bluesky { return blueskyConnected }
            return !(accountsByPlatform[platform] ?? []).isEmpty
        }
    }

    private func res(_ accountId: String, _ platform: String, success: Bool,
                     postUrl: String? = nil, postId: String? = nil, error: String? = nil) -> GatewayPublishResult {
        var obj: [String: Any] = ["account_id": accountId, "platform": platform, "success": success]
        if let postUrl { obj["post_url"] = postUrl }
        if let postId { obj["post_id"] = postId }
        if let error { obj["error"] = error }
        return try! JSONDecoder().decode(GatewayPublishResult.self,
                                         from: try! JSONSerialization.data(withJSONObject: obj))
    }

    private func dispatcher(_ channels: FakeChannels,
                            _ publish: @escaping NativePlatformDispatcher.GatewayPublish) -> NativePlatformDispatcher {
        NativePlatformDispatcher(channels: channels, gatewayPublish: publish,
                                 blueskyPublish: { _, _, _ in "at://fake" })
    }
    private func post(_ platforms: [Platform]) -> QueuedPost {
        QueuedPost(content: "hi", platforms: platforms, sourcePrompt: "", status: .approved)
    }

    // Provider returns only an ID (no URL) — that IS a confirmed publication.
    func testPostIdOnlyCountsAsVerifiedSuccess() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-x"]
        let d = dispatcher(ch) { _, _, _ in [self.res("acct-x", "x", success: true, postId: "1850000000000")] }
        let r = await d.dispatch(post([.x]))
        XCTAssertEqual(r[.x], .success("1850000000000"), "an id-only receipt must be a verified success, not unverified")
    }

    // A requested account with NO result in the response → failed, not success.
    func testMissingRequestedAccountIsFailure() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a", "acct-b"]
        let d = dispatcher(ch) { _, _, _ in
            [self.res("acct-a", "x", success: true, postUrl: "https://x.com/a")] // acct-b missing
        }
        let r = await d.dispatch(post([.x]))
        if case .failed = r[.x] {} else { XCTFail("missing requested account must be .failed, got \(String(describing: r[.x]))") }
    }

    // Duplicate results for the same account → not treated as clean success.
    func testDuplicateAccountResultIsFailure() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a"]
        let d = dispatcher(ch) { _, _, _ in
            [self.res("acct-a", "x", success: true, postUrl: "https://x.com/1"),
             self.res("acct-a", "x", success: true, postUrl: "https://x.com/2")]
        }
        let r = await d.dispatch(post([.x]))
        if case .failed = r[.x] {} else { XCTFail("duplicate account result must be .failed, got \(String(describing: r[.x]))") }
    }

    // Multiple accounts on one platform, all succeed → success.
    func testMultipleAccountsAllSucceed() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a", "acct-b"]
        let d = dispatcher(ch) { _, _, _ in
            [self.res("acct-a", "x", success: true, postUrl: "https://x.com/a"),
             self.res("acct-b", "x", success: true, postId: "999")]
        }
        let r = await d.dispatch(post([.x]))
        XCTAssertTrue(r[.x]?.isSuccess ?? false, "all requested accounts succeeded → success")
    }

    // Multiple accounts, one fails → failed (partial is not success).
    func testMultipleAccountsOneFailsIsFailure() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-a", "acct-b"]
        let d = dispatcher(ch) { _, _, _ in
            [self.res("acct-a", "x", success: true, postUrl: "https://x.com/a"),
             self.res("acct-b", "x", success: false, error: "permission denied")]
        }
        let r = await d.dispatch(post([.x]))
        if case .failed = r[.x] {} else { XCTFail("partial success must be .failed, got \(String(describing: r[.x]))") }
    }

    // An UNEXPECTED account in the response doesn't rescue a missing requested one.
    func testUnexpectedAccountDoesNotCount() async {
        let ch = FakeChannels(); ch.accountsByPlatform[.x] = ["acct-requested"]
        let d = dispatcher(ch) { _, _, _ in
            [self.res("acct-SOMEONE-ELSE", "x", success: true, postUrl: "https://x.com/other")]
        }
        let r = await d.dispatch(post([.x]))
        if case .failed = r[.x] {} else { XCTFail("unexpected-only account must be .failed for the requested one, got \(String(describing: r[.x]))") }
    }
}
