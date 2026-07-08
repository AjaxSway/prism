import Foundation

// MARK: - Bluesky Native Service
// Posts directly to Bluesky via AT Protocol.
// Authentication: App Password (no OAuth app needed — user creates in Bluesky settings).
// API: bsky.social XRPC endpoints.

struct BlueskyNativeService {
    static let shared = BlueskyNativeService()
    private init() {}

    private let host = "https://bsky.social"

    // MARK: - Post text (with optional image URL)

    func post(text: String, imageURL: URL? = nil, connection: PlatformConnection) async throws -> String {
        guard let handle = connection.handle, let appPassword = connection.accessToken else {
            throw BlueskyError.notConnected
        }

        let session = try await createSession(handle: handle, appPassword: appPassword)

        // If there's an image, upload it first
        var embed: [String: Any]? = nil
        if let imageURL = imageURL {
            if let blob = try? await uploadImage(url: imageURL, session: session) {
                embed = [
                    "$type": "app.bsky.embed.images",
                    "images": [
                        [
                            "image": blob,
                            "alt": text.prefix(300).description
                        ]
                    ]
                ]
            }
        }

        let postURI = try await createPost(text: text, embed: embed, session: session)
        return postURI
    }

    // MARK: - AT Protocol: Create Session

    private struct BlueskySession {
        let did: String
        let accessJwt: String
    }

    private func createSession(handle: String, appPassword: String) async throws -> BlueskySession {
        guard let url = URL(string: "\(host)/xrpc/com.atproto.server.createSession") else {
            throw BlueskyError.invalidEndpoint
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "identifier": handle,
            "password": appPassword
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BlueskyError.authFailed
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let did = json["did"] as? String,
              let jwt = json["accessJwt"] as? String else {
            throw BlueskyError.parseError
        }
        return BlueskySession(did: did, accessJwt: jwt)
    }

    // MARK: - AT Protocol: Create Post

    private func createPost(text: String, embed: [String: Any]?, session: BlueskySession) async throws -> String {
        guard let url = URL(string: "\(host)/xrpc/com.atproto.repo.createRecord") else {
            throw BlueskyError.invalidEndpoint
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessJwt)", forHTTPHeaderField: "Authorization")

        var record: [String: Any] = [
            "$type": "app.bsky.feed.post",
            "text": String(text.prefix(300)),
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]
        if let embed = embed {
            record["embed"] = embed
        }

        let body: [String: Any] = [
            "repo": session.did,
            "collection": "app.bsky.feed.post",
            "record": record
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BlueskyError.postFailed
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uri = json["uri"] as? String else {
            throw BlueskyError.parseError
        }
        return uri
    }

    // MARK: - AT Protocol: Upload Image Blob

    private func uploadImage(url: URL, session: BlueskySession) async throws -> [String: Any] {
        let (imageData, _) = try await URLSession.shared.data(from: url)

        guard let uploadURL = URL(string: "\(host)/xrpc/com.atproto.repo.uploadBlob") else {
            throw BlueskyError.invalidEndpoint
        }
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessJwt)", forHTTPHeaderField: "Authorization")
        req.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BlueskyError.uploadFailed
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let blob = json["blob"] as? [String: Any] else {
            throw BlueskyError.parseError
        }
        return blob
    }
}

// MARK: - Errors

enum BlueskyError: LocalizedError {
    case notConnected, invalidEndpoint, authFailed, postFailed, uploadFailed, parseError

    var errorDescription: String? {
        switch self {
        case .notConnected:     return "Bluesky not connected. Add your app password in Channels."
        case .invalidEndpoint:  return "Bluesky endpoint invalid."
        case .authFailed:       return "Bluesky authentication failed. Check your handle and app password."
        case .postFailed:       return "Bluesky post failed. Check your connection."
        case .uploadFailed:     return "Bluesky image upload failed."
        case .parseError:       return "Bluesky response could not be parsed."
        }
    }
}
