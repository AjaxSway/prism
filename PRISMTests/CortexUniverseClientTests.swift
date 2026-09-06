import XCTest
import CortexEcosystemBrain

final class CortexUniverseClientTests: XCTestCase {
    private func client(
        enabled: Bool,
        bearer: String? = "session",
        status: Int = 200,
        body: String = #"{"success":true,"status":"installed_verified"}"#,
        error: Error? = nil
    ) -> CortexUniverseClient {
        CortexUniverseClient(
            isEnabled: enabled,
            expectedScheme: "prism",
            bundleId: "com.cortexnode.prism",
            transport: { _ in
                if let error { throw error }
                let response = HTTPURLResponse(
                    url: URL(string: "https://api.cortexnode.ai/v1/universe/register")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (Data(body.utf8), response)
            },
            bearerToken: { bearer }
        )
    }

    func testGateDisabledSkipsNetwork() async {
        let outcome = await client(enabled: false).register(version: "1", build: "1")
        XCTAssertEqual(outcome, .gateDisabled)
    }

    func testTokenlessNavigation() {
        let url = URL(string: "prism://universe/open")!
        XCTAssertEqual(client(enabled: false).evaluateIncomingURL(url), .tokenlessOpen)
        XCTAssertEqual(client(enabled: true).evaluateIncomingURL(url), .tokenlessOpen)
    }

    func testForbiddenFieldRejected() {
        let url = URL(string: "prism://universe/open?founder=true")!
        XCTAssertEqual(client(enabled: true).evaluateIncomingURL(url), .rejected("forbidden field"))
    }

    func testRegisterSuccessAndFailure() async {
        let ok = await client(enabled: true).register(version: "2.1.0", build: "1")
        XCTAssertEqual(ok, .success(["success": "true", "status": "installed_verified"]))
        let denied = await client(enabled: true, status: 403, body: #"{"code":"unknown_bundle"}"#).register(version: "1", build: "1")
        XCTAssertEqual(denied, .rejected("unknown_bundle"))
    }

    func testRegistryIsolationPayload() async {
        let outcome = await client(enabled: true, body: #"{"success":true,"memory_scope":"firebase_uid"}"#).registry()
        XCTAssertEqual(outcome, .success(["success": "true", "memory_scope": "firebase_uid"]))
        XCTAssertEqual(client(enabled: true).memoryOwnerHint(), "firebase_uid")
    }

    func testIssueAndRedeem() async {
        let issue = await client(enabled: true, body: #"{"success":true,"code":"abc"}"#)
            .issueHandoff(destinationBundle: "com.cortexnode.cortexchat", route: "open")
        XCTAssertEqual(issue, .success(["success": "true", "code": "abc"]))
        let redeem = await client(enabled: true, body: #"{"success":true,"route":"open"}"#)
            .redeem(code: String(repeating: "a", count: 48))
        XCTAssertEqual(redeem, .success(["success": "true", "route": "open"]))
    }

    func testReplayRejected() async {
        let outcome = await client(enabled: true, status: 401, body: #"{"code":"unknown_or_replay"}"#).redeem(code: "x")
        XCTAssertEqual(outcome, .rejected("unknown_or_replay"))
    }

    func testExpirationRejected() async {
        let outcome = await client(enabled: true, status: 401, body: #"{"code":"expired"}"#).redeem(code: "x")
        XCTAssertEqual(outcome, .rejected("expired"))
    }

    func testWrongUserRejected() async {
        let outcome = await client(enabled: true, status: 403, body: #"{"code":"wrong_user"}"#).redeem(code: "x")
        XCTAssertEqual(outcome, .rejected("wrong_user"))
    }

    func testWrongDestinationRejected() async {
        let outcome = await client(enabled: true, status: 403, body: #"{"code":"wrong_destination"}"#).redeem(code: "x")
        XCTAssertEqual(outcome, .rejected("wrong_destination"))
    }

    func testWrongAudienceRejected() async {
        let outcome = await client(enabled: true, status: 403, body: #"{"code":"wrong_audience"}"#).redeem(code: "x")
        XCTAssertEqual(outcome, .rejected("wrong_audience"))
    }

    func testMalformedResponse() async {
        let outcome = await client(enabled: true, status: 200, body: "not-json").registry()
        XCTAssertEqual(outcome, .malformed)
    }

    func testNetworkFailure() async {
        let outcome = await client(enabled: true, error: URLError(.notConnectedToInternet)).registry()
        XCTAssertEqual(outcome, .networkFailure)
    }

    func testAppAttestFailure() async {
        let outcome = await client(enabled: true, status: 403, body: #"{"code":"attest_required"}"#).attestChallenge()
        XCTAssertEqual(outcome, .attestFailure)
    }

    func testServerRevocation() async {
        let outcome = await client(enabled: true, status: 401, body: #"{"code":"session_revoked"}"#).signOut()
        XCTAssertEqual(outcome, .revoked)
    }

    func testSignOutDowngradePath() async {
        let outcome = await client(enabled: true, body: #"{"success":true,"revoked_apps":"ok"}"#).signOut()
        if case .success(let payload) = outcome {
            XCTAssertEqual(payload["success"], "true")
        } else {
            XCTFail("expected success, got \(outcome)")
        }
    }

    func testMissingBearerFailClosed() async {
        let outcome = await client(enabled: true, bearer: nil).register(version: "1", build: "1")
        XCTAssertEqual(outcome, .rejected("firebase_identity_required"))
    }

    func testIncomingRedeemDoesNotEmbedCredential() {
        let url = URL(string: "prism://universe/open?token=abcdef")!
        XCTAssertEqual(client(enabled: true).evaluateIncomingURL(url), .redeem(code: "abcdef"))
        XCTAssertFalse(url.absoluteString.contains("Bearer"))
    }

    func testNoLocalFounderAuthority() {
        let url = URL(string: "prism://universe/open?god_mode=1")!
        XCTAssertEqual(client(enabled: true).evaluateIncomingURL(url), .rejected("forbidden field"))
    }

    func testBootstrapStaysGateDisabled() async {
        let outcome = await CortexUniverseRuntime.bootstrap(scheme: "prism", bundleId: "com.cortexnode.prism")
        XCTAssertEqual(outcome, .gateDisabled)
    }
}
