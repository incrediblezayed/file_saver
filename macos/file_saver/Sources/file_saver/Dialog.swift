//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 23/06/21.
//

import FlutterMacOS
import Foundation

class Dialog: NSObject {

    func saveAs(_ request: SaveRequest) async throws -> String? {
        let bytes = request.bytes?.data
        let sourcePath = request.sourcePath
        guard bytes != nil || sourcePath != nil else {
            throw PigeonError(
                code: "invalid_arguments",
                message: "Either bytes or sourcePath must be supplied",
                details: nil
            )
        }
        let fileName = request.fileNameWithExtension
        let initialDirectory = request.initialDirectory
        let dialogTitle = request.dialogTitle

        let url: URL? = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSSavePanel()
                if let initialDirectory = initialDirectory, !initialDirectory.isEmpty {
                    panel.directoryURL = URL(fileURLWithPath: initialDirectory)
                } else {
                    panel.directoryURL = FileManager.default.urls(
                        for: .desktopDirectory,
                        in: .userDomainMask
                    ).first
                }
                panel.nameFieldStringValue = fileName
                panel.canCreateDirectories = true
                panel.allowsOtherFileTypes = true
                if let dialogTitle = dialogTitle, !dialogTitle.isEmpty {
                    panel.title = dialogTitle
                    panel.message = dialogTitle
                } else {
                    panel.title =
                        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
                }
                panel.level = .mainMenu
                panel.begin { response in
                    continuation.resume(returning: response == .OK ? panel.url : nil)
                }
            }
        }
        guard let url = url else { return nil }

        try await Dialog.write(bytes: bytes, sourcePath: sourcePath, to: url)
        return url.absoluteString
    }

    /// Copies or writes the payload off the main thread.
    private static func write(bytes: Data?, sourcePath: String?, to url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    if let sourcePath = sourcePath {
                        try copy(from: URL(fileURLWithPath: sourcePath), to: url)
                    } else if let bytes = bytes {
                        try bytes.write(to: url)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(
                        throwing: PigeonError(
                            code: "save_failed",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )
                }
            }
        }
    }

    private static func copy(from source: URL, to destination: URL) throws {
        guard let input = InputStream(url: source),
            let output = OutputStream(url: destination, append: false)
        else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileNoSuchFileError,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open \(source.path)"]
            )
        }
        input.open()
        output.open()
        defer {
            input.close()
            output.close()
        }
        var buffer = [UInt8](repeating: 0, count: 1 << 20)
        while true {
            let read = input.read(&buffer, maxLength: buffer.count)
            if read < 0 {
                throw input.streamError ?? NSError(domain: NSPOSIXErrorDomain, code: Int(EIO))
            }
            if read == 0 {
                return
            }
            var offset = 0
            while offset < read {
                let written = buffer.withUnsafeBufferPointer { pointer in
                    output.write(pointer.baseAddress! + offset, maxLength: read - offset)
                }
                if written <= 0 {
                    throw output.streamError ?? NSError(domain: NSPOSIXErrorDomain, code: Int(EIO))
                }
                offset += written
            }
        }
    }
}
