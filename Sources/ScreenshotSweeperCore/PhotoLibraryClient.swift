import Foundation
import Photos

public struct ScreenshotCandidate: Sendable {
    public let localIdentifier: String
    public let creationDate: Date?
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let filename: String?
}

public enum PhotoLibraryError: Error, CustomStringConvertible {
    case authorizationDenied(PHAuthorizationStatus)
    case deletionFailed(Error)

    public var description: String {
        switch self {
        case .authorizationDenied(let status):
            return "Photos access was not granted. Current status: \(status.readableName). Open System Settings > Privacy & Security > Photos and allow access."
        case .deletionFailed(let error):
            return "Photos deletion failed: \(error.localizedDescription)"
        }
    }
}

public final class PhotoLibraryClient {
    public init() {}

    public func requestAccess() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibraryError.authorizationDenied(newStatus)
            }
        default:
            throw PhotoLibraryError.authorizationDenied(status)
        }
    }

    public func fetchScreenshots(olderThan policy: RetentionPolicy, limit: Int?) -> [ScreenshotCandidate] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [ScreenshotCandidate] = []

        assets.enumerateObjects { asset, _, stop in
            guard asset.mediaSubtypes.contains(.photoScreenshot) else {
                return
            }

            guard policy.isOlderThanRetention(asset.creationDate) else {
                return
            }

            candidates.append(
                ScreenshotCandidate(
                    localIdentifier: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    filename: asset.value(forKey: "filename") as? String
                )
            )

            if let limit, candidates.count >= limit {
                stop.pointee = true
            }
        }

        return candidates
    }

    public func deleteAssets(with identifiers: [String]) async throws {
        guard identifiers.isEmpty == false else {
            return
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            }
        } catch {
            throw PhotoLibraryError.deletionFailed(error)
        }
    }
}

private extension PHAuthorizationStatus {
    var readableName: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        @unknown default:
            return "unknown"
        }
    }
}
