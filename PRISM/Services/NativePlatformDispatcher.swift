import Foundation

// MARK: - Native Platform Dispatcher
// Bluesky posts on-device. All other platforms publish via CORTEX gateway (/publish).

@MainActor
final class NativePlatformDispatcher {
    static let shared = NativePlatformDispatcher()
    private init() {}

    private let channels = PlatformChannelManager.shared
    private let gateway = PrismGatewayOAuthService.shared

    func dispatch(_ post: QueuedPost, imageURL: URL? = nil) async -> [Platform: DispatchResult] {
        var results: [Platform: DispatchResult] = [:]

        // 1) Platforms the gateway does not yet support (e.g. Facebook, TikTok)
        //    must get an EXPLICIT "unavailable" result. Previously they were
        //    filtered out of every branch and silently vanished from the report.
        let unsupported = post.platforms.filter { !$0.gatewaySupported && $0 != .bluesky }
        for platform in unsupported {
            results[platform] = .unavailable(
                "\(platform.displayName) publishing is not available yet — the gateway adapter is not deployed."
            )
        }

        let gatewayPlatforms = post.platforms.filter { $0.gatewaySupported && $0 != .bluesky }
        let gatewayAccountIds = channels.accountIds(for: gatewayPlatforms)

        if !gatewayPlatforms.isEmpty {
            if gatewayAccountIds.isEmpty {
                // No accounts for any requested gateway platform — distinguish a
                // genuine "not connected" from a hidden refresh/auth failure.
                for platform in gatewayPlatforms {
                    results[platform] = channels.lastRefreshFailed
                        ? .failed("Connection status unavailable — sign-in may have expired. Reconnect and retry.")
                        : .skipped("Not connected")
                }
            } else {
                do {
                    let publishResults = try await gateway.publish(
                        content: post.content,
                        accountIds: gatewayAccountIds,
                        imageURL: imageURL?.absoluteString
                    )
                    for platform in gatewayPlatforms {
                        let platformKey = GatewaySocialAccount.normalizePlatform(platform)
                        let platformResults = publishResults.filter {
                            GatewaySocialAccount.normalizePlatformString($0.platform ?? "") == platformKey
                        }
                        results[platform] = Self.classify(
                            platformResults,
                            isConnected: channels.isConnected(platform)
                        )
                    }
                } catch {
                    for platform in gatewayPlatforms {
                        results[platform] = .failed(error.localizedDescription)
                    }
                }
            }
        }

        if post.platforms.contains(.bluesky) {
            let connection = channels.connection(for: .bluesky)
            if connection.isConnected {
                do {
                    let uri = try await BlueskyNativeService.shared.post(
                        text: post.content,
                        imageURL: imageURL,
                        connection: connection
                    )
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

    /// Pure classification of a single platform's gateway publish results.
    /// Extracted so the success/pending/failed rules are unit-testable without
    /// the shared singletons. Rules:
    ///   • no results for a connected platform → pending (response didn't cover it)
    ///   • no results for a disconnected platform → skipped
    ///   • all succeeded WITH a non-empty post URL → success(url)
    ///   • all succeeded but NO post URL → pending (never a fake "posted")
    ///   • any failure → failed(joined errors)
    nonisolated static func classify(_ platformResults: [GatewayPublishResult], isConnected: Bool) -> DispatchResult {
        if platformResults.isEmpty {
            return isConnected
                ? .pending("No gateway account matched the publish response")
                : .skipped("Not connected")
        }
        if platformResults.allSatisfy(\.success) {
            if let url = platformResults.compactMap(\.postUrl).first, !url.isEmpty {
                return .success(url)
            }
            return .pending("Accepted by gateway; awaiting a confirmed post URL")
        }
        let err = platformResults.compactMap(\.error).joined(separator: "; ")
        return .failed(err.isEmpty ? "Gateway publish failed" : err)
    }
}

// MARK: - Result types

enum DispatchResult: Equatable {
    case success(String)        // post URL or ID
    case failed(String)         // error message
    case skipped(String)        // reason
    case pending(String)        // needs manual step
    case unavailable(String)    // platform not supported by the gateway yet

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .success(let ref):     return "Posted · \(ref)"
        case .failed(let msg):      return "Failed · \(msg)"
        case .skipped(let msg):     return "Skipped · \(msg)"
        case .pending(let msg):     return "Pending · \(msg)"
        case .unavailable(let msg): return "Unavailable · \(msg)"
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
