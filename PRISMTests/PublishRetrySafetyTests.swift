import XCTest
@testable import PRISM

/// Per-account retry safety: a partial failure must NOT cause a retry to repost
/// to accounts that already succeeded. Plus receipt-field trimming/validation.
final class PublishRetrySafetyTests: XCTestCase {

    private func res(_ accountId: String, _ platform: String, success: Bool,
                     postUrl: String? = nil, postId: String? = nil, error: String? = nil) -> GatewayPublishResult {
        var obj: [String: Any] = ["account_id": accountId, "platform": platform, "success": success]
        if let postUrl { obj["post_url"] = postUrl }
        if let postId { obj["post_id"] = postId }
        if let error { obj["error"] = error }
        return try! JSONDecoder().decode(GatewayPublishResult.self,
                                         from: try! JSONSerialization.data(withJSONObject: obj))
    }

    // The core retry-safety guarantee.
    func testPartialFailureRetryTargetsOnlyUnsucceededAccounts() {
        let results = [
            res("acct-a", "x", success: true, postUrl: "https://x.com/a"), // succeeded
            res("acct-b", "x", success: false, error: "rate limited"),      // failed
        ]
        let outcomes = NativePlatformDispatcher.classifyAccounts(
            requestedAccountIds: ["acct-a", "acct-b"], from: results, platformKey: "x")

        XCTAssertEqual(outcomes["acct-a"], .succeeded(receipt: "https://x.com/a"))
        XCTAssertEqual(outcomes["acct-b"], .failed("rate limited"))

        let retry = NativePlatformDispatcher.accountsNeedingRetry(outcomes)
        XCTAssertEqual(retry, ["acct-b"], "retry must NOT include the account that already succeeded")
    }

    // Accepted-without-receipt must also be excluded from retry (may have posted).
    func testAcceptedAccountIsNotRetried() {
        let results = [res("acct-a", "x", success: true, postUrl: nil)] // accepted, no receipt
        let outcomes = NativePlatformDispatcher.classifyAccounts(
            requestedAccountIds: ["acct-a"], from: results, platformKey: "x")
        XCTAssertEqual(outcomes["acct-a"], .accepted)
        XCTAssertTrue(NativePlatformDispatcher.accountsNeedingRetry(outcomes).isEmpty,
                      "an accepted (possibly-posted) account must not be auto-retried")
    }

    // A requested account with no server result is UNKNOWN, not success/failure,
    // but IS eligible for a (safe) retry since nothing was confirmed.
    func testNoResultAccountIsUnknownAndRetriable() {
        let results = [res("acct-a", "x", success: true, postUrl: "https://x.com/a")]
        let outcomes = NativePlatformDispatcher.classifyAccounts(
            requestedAccountIds: ["acct-a", "acct-missing"], from: results, platformKey: "x")
        XCTAssertEqual(outcomes["acct-missing"], .noResult)
        XCTAssertEqual(NativePlatformDispatcher.accountsNeedingRetry(outcomes), ["acct-missing"])
    }

    // Duplicate per-account result is ambiguous → failed (not a clean success).
    func testDuplicateAccountResultIsAmbiguousFailure() {
        let results = [
            res("acct-a", "x", success: true, postUrl: "https://x.com/1"),
            res("acct-a", "x", success: true, postUrl: "https://x.com/2"),
        ]
        let outcomes = NativePlatformDispatcher.classifyAccounts(
            requestedAccountIds: ["acct-a"], from: results, platformKey: "x")
        if case .failed = outcomes["acct-a"] {} else { XCTFail("duplicate → failed") }
    }

    // Receipt validation: whitespace-only URL/ID is NOT a receipt.
    func testWhitespaceReceiptIsNotValid() {
        let r = res("acct-a", "x", success: true, postUrl: "   ", postId: "\n\t")
        XCTAssertNil(r.receipt, "whitespace-only fields must not count as a receipt")
    }

    func testPostIdReceiptIsTrimmed() {
        let r = res("acct-a", "x", success: true, postId: "  1850  ")
        XCTAssertEqual(r.receipt, "1850", "receipt must be trimmed")
    }
}
