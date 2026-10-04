import Foundation

// MARK: - Native Platform Dispatcher
// Bluesky posts on-device. Gateway-OAuth platforms publish via CORTEX gateway (/publish).
// Platforms that are selected but have no publishing path yet (Facebook, TikTok)
// return an explicit .unsupported result — they are NEVER silently dropped.

// The subset of channel queries the dispatcher needs. A protocol so tests can
// inject a lightweight fake instead of PlatformChannelManager.shared (which
// touches Keychain + the network on init). PlatformChannelManager conforms.
@MainActor
protocol DispatcherChannelSource {
    func accountIds(for platforms: [Platform]) -> [String]
    func connection(for platform: Platform) -> PlatformConnection
    func isConnected(_ platform: Platform) -> Bool
}

extension PlatformChannelManager: DispatcherChannelSource {}

@MainActor
final class NativePlatformDispatcher {
    static let shared = NativePlatformDispatcher()

    // Injectable seams so dispatch can be exercised in tests without any public
    // posting. Production uses the real shared services; tests pass fakes.
    typealias GatewayPublish = (_ content: String, _ accountIds: [String], _ imageURL: String?) async throws -> [GatewayPublishResult]
    typealias BlueskyPublish = (_ text: String, _ imageURL: URL?, _ connection: PlatformConnection) async throws -> String

    private let channels: DispatcherChannelSource
    private let gatewayPublish: GatewayPublish
    private let blueskyPublish: BlueskyPublish

    init(
        channels: DispatcherChannelSource = PlatformChannelManager.shared,
        gatewayPublish: GatewayPublish? = nil,
        blueskyPublish: BlueskyPublish? = nil
    ) {
        self.channels = channels
        self.gatewayPublish = gatewayPublish ?? { content, accountIds, imageURL in
            try await PrismGatewayOAuthService.shared.publish(
                content: content,
                accountIds: accountIds,
                imageURL: imageURL
            )
        }
        self.blueskyPublish = blueskyPublish ?? { text, imageURL, connection in
            try await BlueskyNativeService.shared.post(
                text: text,
                imageURL: imageURL,
                connection: connection
            )
        }
    }

    func dispatch(_ post: QueuedPost, imageURL: URL? = nil) async -> [Platform: DispatchResult] {
        var results: [Platform: DispatchResult] = [:]

        // Partition every selected platform by how it can actually be published.
        // Anything that is neither a gateway platform nor Bluesky has no publish
        // path in this build and must be reported, not dropped.
        for platform in post.platforms where !platform.usesGatewayOAuth && platform != .bluesky {
            results[platform] = .unsupported(
                "\(platform.displayName) publishing isn't available yet — the gateway hasn't shipped this platform's OAuth. Nothing was sent."
            )
        }

        // --- Gateway-OAuth platforms (X, Instagram, LinkedIn, Threads, YouTube) ---
        let gatewayPlatforms = post.platforms.filter { $0.usesGatewayOAuth && $0 != .bluesky }
        if !gatewayPlatforms.isEmpty {
            let gatewayAccountIds = channels.accountIds(for: gatewayPlatforms)
            if gatewayAccountIds.isEmpty {
                // No connected accounts for any selected gateway platform.
                for platform in gatewayPlatforms {
                    results[platform] = .skipped("Not connected")
                }
            } else {
                do {
                    let publishResults = try await gatewayPublish(
                        post.content,
                        gatewayAccountIds,
                        imageURL?.absoluteString
                    )
                    for platform in gatewayPlatforms {
                        results[platform] = resolveGatewayResult(for: platform, from: publishResults)
                    }
                } catch {
                    // A thrown error means the whole /publish request failed
                    // (network, 401, 5xx). Report it on every gateway platform
                    // we attempted — never leave one without a result.
                    for platform in gatewayPlatforms {
                        results[platform] = .failed(error.localizedDescription)
                    }
                }
            }
        }

        // --- Bluesky (native, on-device) ---
        if post.platforms.contains(.bluesky) {
            let connection = channels.connection(for: .bluesky)
            if connection.isConnected {
                do {
                    let uri = try await blueskyPublish(post.content, imageURL, connection)
                    results[.bluesky] = .success(uri)
                } catch {
                    results[.bluesky] = .failed(error.localizedDescription)
                }
            } else {
                results[.bluesky] = .skipped("Not connected")
            }
        }

        return results
    }

    /// Maps the gateway's per-account results for a single platform into one
    /// honest DispatchResult. Key correctness rules:
    /// - No matching account result → .pending (we have a connection but the
    ///   server returned nothing for it) or .skipped if not connected.
    /// - All accounts succeeded WITH a post URL → .success(url).
    /// - Succeeded but NO post URL returned → .unverified. The provider accepted
    ///   the request but gave no receipt; we must not fabricate "posted".
    /// - Any failure → .failed with the server's error text.
    private func resolveGatewayResult(
        for platform: Platform,
        from publishResults: [GatewayPublishResult]
    ) -> DispatchResult {
        let platformKey = GatewaySocialAccount.normalizePlatform(platform)
        let platformResults = publishResults.filter {
            GatewaySocialAccount.normalizePlatformString($0.platform ?? "") == platformKey
        }

        if platformResults.isEmpty {
            return channels.isConnected(platform)
                ? .pending("No gateway account matched the server response")
                : .skipped("Not connected")
        }

        if platformResults.allSatisfy(\.success) {
            if let url = platformResults.compactMap(\.postUrl).first, !url.isEmpty {
                return .success(url)
            }
            // Accepted but unverifiable — honest status, never a fake receipt.
            return .unverified("Accepted by the provider, but no post URL was returned to confirm publication")
        }

        let err = platformResults.compactMap(\.error).filter { !$0.isEmpty }.joined(separator: "; ")
        return .failed(err.isEmpty ? "Gateway publish failed" : err)
    }
}

// MARK: - Result types

enum DispatchResult: Equatable {
    case success(String)        // post URL or ID — a real, verifiable receipt
    case unverified(String)     // provider accepted the request, no receipt URL returned
    case failed(String)         // error message
    case skipped(String)        // reason (e.g. not connected)
    case pending(String)        // needs a manual step / awaiting server state
    case unsupported(String)    // platform has no publish path in this build

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// True when the post attempt reached the provider and was accepted, even
    /// if a confirming URL wasn't returned. Distinct from a verified success.
    var isAccepted: Bool {
        switch self {
        case .success, .unverified: return true
        default: return false
        }
    }

    var label: String {
        switch self {
        case .success(let ref):     return "Posted · \(ref)"
        case .unverified(let msg):  return "Sent (unverified) · \(msg)"
        case .failed(let msg):      return "Failed · \(msg)"
        case .skipped(let msg):     return "Skipped · \(msg)"
        case .pending(let msg):     return "Pending · \(msg)"
        case .unsupported(let msg): return "Unavailable · \(msg)"
        }
    }
}

// MARK: - Errors

enum NativeDispatchError: LocalizedError {
    case notConnected, invalidEndpoint, postFailed, parseError

    var errorDescription: String? {
        switch self {
        case .notConnected:    return "Platform not connected."
        case .invalidEndpoint: return "Invalid platform endpoint."
        case .postFailed:      return "Post request failed."
        case .parseError:      return "Could not parse platform response."
        }
    }
}
