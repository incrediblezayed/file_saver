import Flutter
import Foundation
import Photos

/// Saves images and videos into the Photos library.
class Gallery {
    /// Returns the new asset's local identifier.
    func save(_ request: SaveRequest) async throws -> String? {
        let resourceType: PHAssetResourceType
        if request.mimeType.hasPrefix("image/") {
            resourceType = .photo
        } else if request.mimeType.hasPrefix("video/") {
            resourceType = .video
        } else {
            throw PigeonError(
                code: "invalid_arguments",
                message: "saveToGallery only accepts image/* or video/* mime types, got '\(request.mimeType)'",
                details: nil
            )
        }
        let bytes = request.bytes?.data
        guard bytes != nil || request.sourcePath != nil else {
            throw PigeonError(
                code: "invalid_arguments",
                message: "Either bytes or sourcePath must be supplied",
                details: nil
            )
        }
        let name = request.fileNameWithExtension

        let fileURL: URL
        var tempDirectory: URL?
        if let sourcePath = request.sourcePath {
            fileURL = URL(fileURLWithPath: sourcePath)
        } else {
            let directory = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
            fileURL = directory.appendingPathComponent(name)
            do {
                try await Gallery.write(bytes!, to: fileURL, in: directory)
            } catch {
                throw PigeonError(
                    code: "creating_temp_file_failed",
                    message: error.localizedDescription,
                    details: nil
                )
            }
            tempDirectory = directory
        }
        defer {
            if let tempDirectory = tempDirectory {
                try? FileManager.default.removeItem(at: tempDirectory)
            }
        }

        let albumTitle = request.album?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let wantsAlbum = !albumTitle.isEmpty
        // Adding to an album means reading the library, which needs full access.
        guard await Gallery.requestAccess(readWrite: wantsAlbum) else {
            throw PigeonError(
                code: "permission_denied",
                message: wantsAlbum
                    ? "Photo library access was denied. Add NSPhotoLibraryUsageDescription to Info.plist; saving into an album needs read access."
                    : "Photo library add access was denied. Add NSPhotoLibraryAddUsageDescription to Info.plist.",
                details: nil
            )
        }
        let collection = wantsAlbum ? await Gallery.ensureAlbum(albumTitle) : nil
        return try await Gallery.add(fileURL: fileURL, name: name, resourceType: resourceType, to: collection)
    }

    /// Writes the payload to disk off the main thread.
    private static func write(_ bytes: Data, to fileURL: URL, in directory: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    try bytes.write(to: fileURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func requestAccess(readWrite: Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: readWrite ? .readWrite : .addOnly) { status in
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    /// Finds the album named [title], creating it when missing.
    private static func ensureAlbum(_ title: String) async -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        if let existing = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: options
        ).firstObject {
            return existing
        }
        return await withCheckedContinuation { continuation in
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                placeholder = PHAssetCollectionChangeRequest
                    .creationRequestForAssetCollection(withTitle: title)
                    .placeholderForCreatedAssetCollection
            }) { success, _ in
                guard success, let identifier = placeholder?.localIdentifier else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(
                    returning: PHAssetCollection.fetchAssetCollections(
                        withLocalIdentifiers: [identifier], options: nil
                    ).firstObject
                )
            }
        }
    }

    private static func add(
        fileURL: URL,
        name: String,
        resourceType: PHAssetResourceType,
        to collection: PHAssetCollection?
    ) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            var localIdentifier: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = name
                request.addResource(with: resourceType, fileURL: fileURL, options: options)
                let placeholder = request.placeholderForCreatedAsset
                localIdentifier = placeholder?.localIdentifier
                if let collection = collection, let placeholder = placeholder,
                    let albumRequest = PHAssetCollectionChangeRequest(for: collection)
                {
                    albumRequest.addAssets([placeholder] as NSArray)
                }
            }) { success, error in
                if success {
                    continuation.resume(returning: localIdentifier)
                } else {
                    continuation.resume(
                        throwing: PigeonError(
                            code: "save_failed",
                            message: error?.localizedDescription ?? "Unknown error",
                            details: nil
                        )
                    )
                }
            }
        }
    }
}
