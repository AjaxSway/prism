import XCTest
@testable import PRISM

// Exercises NativePlatformDispatcher end-to-end with injected fakes — NO public
// posting, no network. Covers the repaired defects:
//   • Facebook/TikTok return an explicit .unsupported result (never dropped).
//   • success-without-postUrl becomes .unverified (never a fake "posted").
//   • mixed success/failure across platforms.
//   • publish throw → every attempted platform reports .failed.
//   • not-connected → .skipped.
@MainActor
final class NativePlatformDispatcherTests: XCTestCase {

    // MARK: - Fake channel source

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

    private func gatewayResult(
        accountId: String,
        platform: String,
        success: Bool,
        postUrl: String? = nil,
        error: String? = nil
    ) -> GatewayPublishResult {
        // GatewayPublishResult is Decodable-only; build it from JSON.
        let json = """
        {"account_id":"\(accountId)","platform":"\(platform)","success":\(success)\
        \(postUrl.map { ",\"post_url\":\"\($0)\"" } ?? "")\
        \(error.map { ",\"error\":\"\($0)\"" } ?? "")}
        """
        return try! JSONDecoder().decode(GatewayPublishResult.self, from: Data(json.utf8))
    }

    private func makeDispatcher(
        channels: FakeChannels,
        publish: @escaping NativePlatformDispatcher.GatewayPublish
    ) -> NativePlatformDispatcher {
        NativePlatformDispatcher(
            channels: channels,
            gatewayPublish: publish,
            blueskyPublish: { _, _, _ in "at://did:plc:fake/post/1" }
        )
    }

    // MARK: - Defect #1: unsupported platforms are reported, not dropped

    func testFacebookAndTiktokReturnUnsupported() async {
        let channels = FakeChannels()
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            XCTFail("gateway publish should not be called for unsupported-only post")
            return []
        }
        let post = QueuedPost(content: "hi", platforms: [.facebook, .tiktok], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        XCTAssertEqual(results.count, 2, "both selected platforms must have a result")
        if case .unsupported = results[.facebook] {} else { XCTFail("facebook should be .unsupported, got \(String(describing: results[.facebook]))") }
        if case .unsupported = results[.tiktok] {} else { XCTFail("tiktok should be .unsupported, got \(String(describing: results[.tiktok]))") }
    }

    // MARK: - Defect #2: accepted-without-URL is .unverified, never fake success

    func testSuccessWithoutPostUrlIsUnverified() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.x] = ["acct-x"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            [self.gatewayResult(accountId: "acct-x", platform: "x", success: true, postUrl: nil)]
        }
        let post = QueuedPost(content: "hi", platforms: [.x], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        if case .unverified = results[.x] {} else {
            XCTFail("success w/o postUrl must be .unverified, got \(String(describing: results[.x]))")
        }
        XCTAssertFalse(results[.x]?.isSuccess ?? true, "must not report a verified success")
        XCTAssertTrue(results[.x]?.isAccepted ?? false, "must be counted as accepted")
    }

    func testSuccessWithPostUrlIsVerifiedSuccess() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.instagram] = ["acct-ig"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            [self.gatewayResult(accountId: "acct-ig", platform: "instagram", success: true, postUrl: "https://instagram.com/p/REAL")]
        }
        let post = QueuedPost(content: "hi", platforms: [.instagram], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        XCTAssertEqual(results[.instagram], .success("https://instagram.com/p/REAL"))
    }

    // MARK: - Not connected → skipped (distinct from unsupported)

    func testGatewayPlatformNotConnectedIsSkipped() async {
        let channels = FakeChannels() // no accounts
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            XCTFail("publish should not be called when nothing is connected")
            return []
        }
        let post = QueuedPost(content: "hi", platforms: [.linkedin], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        if case .skipped = results[.linkedin] {} else {
            XCTFail("not-connected gateway platform should be .skipped, got \(String(describing: results[.linkedin]))")
        }
    }

    // MARK: - Mixed success + failure across platforms

    func testMixedSuccessAndFailure() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.x] = ["acct-x"]
        channels.accountsByPlatform[.linkedin] = ["acct-li"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            [
                self.gatewayResult(accountId: "acct-x", platform: "x", success: true, postUrl: "https://x.com/REAL"),
                self.gatewayResult(accountId: "acct-li", platform: "linkedin", success: false, error: "token expired"),
            ]
        }
        let post = QueuedPost(content: "hi", platforms: [.x, .linkedin], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        XCTAssertEqual(results[.x], .success("https://x.com/REAL"))
        XCTAssertEqual(results[.linkedin], .failed("token expired"))
    }

    // MARK: - publish throw → every attempted platform reports failed

    func testPublishThrowFailsAllGatewayPlatforms() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.x] = ["acct-x"]
        channels.accountsByPlatform[.threads] = ["acct-th"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            throw GatewayOAuthError.serverError("Publish failed (503)")
        }
        let post = QueuedPost(content: "hi", platforms: [.x, .threads], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        XCTAssertEqual(results.count, 2)
        for p in [Platform.x, .threads] {
            if case .failed = results[p] {} else {
                XCTFail("\(p) should be .failed after publish throw, got \(String(describing: results[p]))")
            }
        }
    }

    // MARK: - Mixed supported + unsupported in one post

    func testSupportedAndUnsupportedTogether() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.x] = ["acct-x"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            [self.gatewayResult(accountId: "acct-x", platform: "x", success: true, postUrl: "https://x.com/OK")]
        }
        let post = QueuedPost(content: "hi", platforms: [.x, .facebook], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        XCTAssertEqual(results[.x], .success("https://x.com/OK"))
        if case .unsupported = results[.facebook] {} else {
            XCTFail("facebook should be .unsupported even alongside a supported platform")
        }
    }

    // MARK: - Connected gateway platform with no matching server result → pending

    func testConnectedButNoMatchingResultIsPending() async {
        let channels = FakeChannels()
        channels.accountsByPlatform[.youtube] = ["acct-yt"]
        let dispatcher = makeDispatcher(channels: channels) { _, _, _ in
            // Server returned a result for a DIFFERENT platform only.
            [self.gatewayResult(accountId: "acct-other", platform: "x", success: true, postUrl: "https://x.com/OK")]
        }
        let post = QueuedPost(content: "hi", platforms: [.youtube], sourcePrompt: "", status: .approved)

        let results = await dispatcher.dispatch(post)

        if case .pending = results[.youtube] {} else {
            XCTFail("connected platform with no matching result should be .pending, got \(String(describing: results[.youtube]))")
        }
    }
}
