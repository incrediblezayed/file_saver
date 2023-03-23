//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 23/06/21.
//

import Foundation
import FlutterMacOS

class Dialog: NSObject {
    
    func openSaveAsDialog(params: Params, result: @escaping FlutterResult){
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        panel.nameFieldStringValue = params.fileName!+"."+params.ext!
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = true
        panel.title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        panel.level = .mainMenu
        panel.begin{ (response) in if response.rawValue == NSApplication.ModalResponse.OK.rawValue{
            guard let url = panel.url else {return }
            self.saveFile(byteData: params.bytes!, url: url, fileName: params.fileName ?? "File", ext: params.ext!, result: result)
        }
        else{
            return
        }
        }
    }
    private func saveFile(byteData: [UInt8],url: URL,fileName: String, ext: String, result: @escaping FlutterResult){
        do {
            let data = Data(byteData)
            try data.write(to: url)
            result(url.absoluteString)
        } catch  {
            result("Failed to save file")
        }
        
    }
}
