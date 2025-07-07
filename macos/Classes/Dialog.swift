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

        var fileNameWithExtension = params.fileName
        if params.includeExtension && fileNameWithExtension != nil {
            if params.fileExtension != nil
                && params.fileExtension!.starts(with: ".")
            {
                fileNameWithExtension! += params.fileExtension!
            } else {
                fileNameWithExtension! += ".\(params.fileExtension!)"
            }
        }
        panel.nameFieldStringValue = fileNameWithExtension!
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = true
        panel.title =
            Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        panel.level = .mainMenu
        panel.begin { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else { return }
                self.saveFile(
                    byteData: params.bytes!,
                    url: url,
                    result: result
                )
            } else {
                return
            }
        }
    }
    private func saveFile(
        byteData: [UInt8],
        url: URL,
        result: @escaping FlutterResult
    ) {
        do {
            let data = Data(byteData)
            try data.write(to: url)
            result(url.absoluteString)
        } catch {
            result("Failed to save file")
        }

    }
}
