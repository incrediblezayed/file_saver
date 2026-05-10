//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 23/06/21.
//

import FlutterMacOS
import Foundation

class Dialog: NSObject {

    func openSaveAsDialog(params: Params, result: @escaping FlutterResult) {
        let panel = NSSavePanel()
        panel.directoryURL =
            FileManager.default.urls(
                for: .desktopDirectory,
                in: .userDomainMask
            ).first

        var fileNameWithExtension = params.fileName ?? "file"
        if params.includeExtension, let fileExtension = params.fileExtension,
            !fileExtension.isEmpty
        {
            if fileExtension.starts(with: ".") {
                fileNameWithExtension += fileExtension
            } else {
                fileNameWithExtension += ".\(fileExtension)"
            }
        }
        panel.nameFieldStringValue = fileNameWithExtension
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = true
        panel.title =
            Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        panel.level = .mainMenu
        panel.begin { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else {
                    result(nil)
                    return
                }
                self.saveFile(
                    byteData: params.bytes,
                    sourcePath: params.sourcePath,
                    url: url,
                    result: result
                )
            } else {
                result(nil)
            }
        }
    }
    private func saveFile(
        byteData: [UInt8]?,
        sourcePath: String?,
        url: URL,
        result: @escaping FlutterResult
    ) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            if let sourcePath = sourcePath {
                try FileManager.default.copyItem(
                    at: URL(fileURLWithPath: sourcePath),
                    to: url
                )
            } else if let byteData = byteData {
                let data = Data(byteData)
                try data.write(to: url)
            } else {
                result(
                    FlutterError(
                        code: "invalid_arguments",
                        message: "Either bytes or sourcePath must be supplied",
                        details: nil
                    )
                )
                return
            }
            result(url.absoluteString)
        } catch {
            result("Failed to save file")
        }

    }
}
