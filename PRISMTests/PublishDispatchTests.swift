import XCTest
@testable import PRISM

/// Covers the publishing-repair defects:
///  A) unsupported platforms (Facebook/TikTok) must be explicit, never silent.
///  B) success is only claimed with a real receipt URL — never a fake "posted".
///  C) classification of mixed / failed / empty gateway responses.
final class PublishDispatchTests: XCTestCase {

    // Build a GatewayPublishResult through its real JSON contract.
    private func result(platform: String, success: Bool, postUrl: String? = nil, error: String? = nil) -> GatewayPublishResult {
        var obj: [String: Any] = ["account_id": "acct_\(platform)", "platform": platform, "success": success]
        if let postUrl { obj["post_url"] = postUrl }
        if let error { obj["error"] = error }
        let data = try! JSONSerialization.data(withJSONObject: obj)
        return try! JSONDecoder().decode(GatewayPublishResult.self, from: data)
    }

    // MARK: - Defect B: no fake "posted"

    func testSuccessRequiresRealReceiptURL() {
        let r = [result(platform: "x", success: true, postUrl: "https://x.com/u/status/123")]
        XCTAssertEqual(NativePlatformDispatcher.classify(r, isConnected: true),
                       .success("https://x.com/u/status/123"))
    }

    func testAcceptedWithoutURLIsPendingNotFakePosted() {
        let r = [result(platform: "x", success: true, postUrl: nil)]
        let outcome = NativePlatformDispatcher.classify(r, isConnected: true)
        // Must NOT be a success carrying the literal "posted".
        XCTAssertNotEqual(outcome, .success("posted"))
        if case .pending = outcome {} else { XCTFail("expected .pending, got \(outcome)") }
    }

    func testEmptyURLStringIsPendingNotSuccess() {
        let r = [result(platform: "x", success: true, postUrl: "")]
        if case .pending = NativePlatformDispatcher.classify(r, isConnected: true) {} else {
            XCTFail("empty url must be pending")
        }
    }

    // MARK: - Defect C: failures and empties

    func testFailurePropagatesError() {
        let r = [result(platform: "x", success: false, error: "token expired")]
        XCTAssertEqual(NativePlatformDispatcher.classify(r, isConnected: true), .failed("token expired"))
    }

    func testEmptyResultsConnectedIsPending() {
        if case .pending = NativePlatformDispatcher.classify([], isConnected: true) {} else {
            XCTFail("connected + no response → pending")
        }
    }

    func testEmptyResultsDisconnectedIsSkipped() {
        if case .skipped = NativePlatformDispatcher.classify([], isConnected: false) {} else {
            XCTFail("disconnected + no response → skipped")
        }
    }

    func testMixedSuccessAndFailureIsFailed() {
        let r = [result(platform: "x", success: true, postUrl: "https://x.com/1"),
                 result(platform: "x", success: false, error: "rate limited")]
        if case .failed = NativePlatformDispatcher.classify(r, isConnected: true) {} else {
            XCTFail("any failure → failed")
        }
    }

    // MARK: - Defect A: platform capability flags

    func testFacebookAndTikTokAreNotGatewaySupported() {
        XCTAssertFalse(Platform.facebook.gatewaySupported)
        XCTAssertFalse(Platform.tiktok.gatewaySupported)
    }

    func testSupportedGatewayPlatforms() {
        XCTAssertTrue(Platform.x.gatewaySupported)
        XCTAssertTrue(Platform.instagram.gatewaySupported)
        XCTAssertTrue(Platform.linkedin.gatewaySupported)
        XCTAssertTrue(Platform.threads.gatewaySupported)
        XCTAssertTrue(Platform.youtube.gatewaySupported)
    }

    func testBlueskyIsNotGatewaySupportedButHandledNatively() {
        XCTAssertFalse(Platform.bluesky.gatewaySupported)
    }

    func testDisplayNamesPresentForAllPlatforms() {
        for p in Platform.allCases {
            XCTAssertFalse(p.displayName.isEmpty, "\(p) needs a display name")
        }
    }
}
