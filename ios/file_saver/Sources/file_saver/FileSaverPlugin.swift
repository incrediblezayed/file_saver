import Flutter
import UIKit

public class FileSaverPlugin: NSObject, FlutterPlugin, FileSaverHostApi {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FileSaverPlugin()
        FileSaverHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    private let dialog = Dialog()
    private let gallery = Gallery()

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
        try await gallery.save(request)
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
