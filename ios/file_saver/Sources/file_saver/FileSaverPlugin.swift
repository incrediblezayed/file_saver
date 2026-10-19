import Flutter
import UIKit

public class FileSaverPlugin: NSObject, FlutterPlugin, FileSaverHostApi {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FileSaverPlugin()
        FileSaverHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    private let dialog = Dialog()
    #if FILE_SAVER_PHOTOS
    private let gallery = Gallery()
    #endif

    func saveFile(request: SaveRequest) async throws -> String? {
        throw PigeonError(
            code: "unsupported",
            message: "saveFile is implemented in Dart on iOS",
            details: nil
        )
    }

    func saveAs(request: SaveRequest) async throws -> String? {
        try await dialog.saveAs(request)
    }

    func saveToGallery(request: SaveRequest) async throws -> String? {
        #if FILE_SAVER_PHOTOS
        try await gallery.save(request)
        #else
        throw PigeonError(
            code: "unsupported",
            message: "Gallery support was not built in. Add NSPhotoLibraryAddUsageDescription to Info.plist (or build with FILE_SAVER_PHOTOS=1), clear the build cache and rebuild. See 'Gallery support on iOS' in the file_saver README.",
            details: nil
        )
        #endif
    }

    func saveToDownloads(request: SaveRequest) async throws -> String? {
        throw PigeonError(
            code: "unsupported",
            message: "iOS has no shared Downloads folder. Use saveFile (the app's Documents folder, visible in Files) or saveAs.",
            details: nil
        )
    }

    func downloadLink(request: DownloadRequest) throws -> String {
        throw PigeonError(
            code: "unsupported",
            message: "downloadLink is only supported on Android and web",
            details: nil
        )
    }
}

extension SaveRequest {
    /// `name.ext`, or just the name when the extension is switched off.
    var fileNameWithExtension: String {
        guard includeExtension, !fileExtension.isEmpty else { return name }
        return name + (fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)")
    }
}

extension Error {
    /// "<domain> <code>", e.g. "NSCocoaErrorDomain 4". Identifies the failure
    /// without the localized description, which can carry file paths (CWE-209).
    var safeDetails: String {
        let error = self as NSError
        return "\(error.domain) \(error.code)"
    }
}
