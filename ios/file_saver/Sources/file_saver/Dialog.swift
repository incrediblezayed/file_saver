//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 22/06/21.
//

import Flutter
import Foundation
import UIKit

class Dialog: NSObject, UIDocumentPickerDelegate {
    /// The call waiting on the picker; nil when no dialog is open.
    private var continuation: CheckedContinuation<String?, Error>?
    private var tempDirectory: URL?
    private let fileManager = FileManager.default

    /// Stages the payload in a temp file, shows the export picker, and resolves
    /// to the chosen path, or nil when the user cancels.
    func saveAs(_ request: SaveRequest) async throws -> String? {
        if continuation != nil {
            throw PigeonError(code: "busy", message: "A saveAs dialog is already open", details: nil)
        }
        let bytes = request.bytes?.data
        let sourcePath = request.sourcePath
        guard bytes != nil || sourcePath != nil else {
            throw PigeonError(
                code: "invalid_arguments",
                message: "Either bytes or sourcePath must be supplied",
                details: nil
            )
        }

        // A private directory per call: same-named files never collide.
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent(request.fileNameWithExtension)
        tempDirectory = directory
        do {
            try await Dialog.stage(bytes: bytes, sourcePath: sourcePath, directory: directory, fileURL: fileURL)
        } catch {
            deleteTemp()
            throw PigeonError(
                code: "creating_temp_file_failed",
                message: error.localizedDescription,
                details: nil
            )
        }

        let initialDirectory = request.initialDirectory
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            DispatchQueue.main.async {
                self.present(fileURL: fileURL, initialDirectory: initialDirectory)
            }
        }
    }

    /// Copies or writes the payload off the main thread.
    private static func stage(bytes: Data?, sourcePath: String?, directory: URL, fileURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    if let sourcePath = sourcePath {
                        try FileManager.default.copyItem(at: URL(fileURLWithPath: sourcePath), to: fileURL)
                    } else if let bytes = bytes {
                        try bytes.write(to: fileURL)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func present(fileURL: URL, initialDirectory: String?) {
        guard let viewController = Dialog.topViewController() else {
            finish(.failure(PigeonError(code: "failure", message: "Failed to launch document Picker", details: nil)))
            return
        }
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
        }
        picker.delegate = self
        if let initialDirectory = initialDirectory, !initialDirectory.isEmpty {
            picker.directoryURL = URL(fileURLWithPath: initialDirectory)
        }
        viewController.present(picker, animated: true, completion: nil)
    }

    /// Resumes the waiting call exactly once and clears state for the next one.
    private func finish(_ result: Result<String?, Error>) {
        deleteTemp()
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }

    private func deleteTemp() {
        guard let tempDirectory = tempDirectory else { return }
        self.tempDirectory = nil
        try? fileManager.removeItem(at: tempDirectory)
    }

    /// The controller that can present right now, even when a sheet is already up.
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        let window = windows.first { $0.isKeyWindow } ?? windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finish(.success(nil))
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        finish(.success(urls.first?.path))
    }
}
