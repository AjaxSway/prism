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

        let gatewayPlatforms = post.platforms.filter { $0.usesGatewayOAuth && $0 != .bluesky }
        let gatewayAccountIds = channels.accountIds(for: gatewayPlatforms)

        if !gatewayAccountIds.isEmpty {
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
                    if platformResults.isEmpty {
                        results[platform] = channels.isConnected(platform)
                            ? .pending("No gateway account matched")
                            : .skipped("Not connected")
                    } else if platformResults.allSatisfy(\.success) {
                        let url = platformResults.compactMap(\.postUrl).first ?? "posted"
                        results[platform] = .success(url)
                    } else {
                        let err = platformResults.compactMap(\.error).joined(separator: "; ")
                        results[platform] = .failed(err.isEmpty ? "Gateway publish failed" : err)
                    }
                }
            } catch {
                for platform in gatewayPlatforms {
                    results[platform] = .failed(error.localizedDescription)
                }
            }
        } else {
            for platform in gatewayPlatforms {
                results[platform] = .skipped("Not connected")
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
}

// MARK: - Result types

enum DispatchResult {
    case success(String)        // post URL or ID
    case failed(String)         // error message
    case skipped(String)        // reason
    case pending(String)        // needs manual step

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .success(let ref):  return "Posted · \(ref)"
        case .failed(let msg):   return "Failed · \(msg)"
        case .skipped(let msg):  return "Skipped · \(msg)"
        case .pending(let msg):  return "Pending · \(msg)"
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
