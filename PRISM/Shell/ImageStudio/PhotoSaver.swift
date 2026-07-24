import Photos
import UIKit

// Downloads a generated image and writes it to the user's Photos library.
// "Image saved" in the UI must never fire before this actually succeeds.
enum PhotoSaveError: LocalizedError {
    case downloadFailed
    case permissionDenied
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .downloadFailed:   return "Could not download the generated image."
        case .permissionDenied: return "Photos access was denied."
        case .writeFailed:      return "Could not save the image to Photos."
        }
    }
}

enum PhotoSaver {
    static func save(imageURL: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: imageURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let image = UIImage(data: data) else {
            throw PhotoSaveError.downloadFailed
        }

        let status = await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { continuation.resume(returning: $0) }
        }
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.writeFailed)
                }
            }
        }
    }
}
