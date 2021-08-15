//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 22/06/21.
//

import Foundation

class Dialog:NSObject, UIDocumentPickerDelegate {
    private var result: FlutterResult?
    private var tempURL: URL?
    private var fileManager = FileManager.default
    private var bytes: [UInt8]?
    
    func openFileManager(byteData: [UInt8],fileName: String, ext: String, result: @escaping FlutterResult){
        self.result = result
        self.bytes = byteData
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "failure", message: "Failed to launch document Picker", details: nil))
            return
        }
        let temp = NSTemporaryDirectory()
        let fileURL = NSURL.fileURL(withPathComponents: [temp, fileName+"."+ext])
        do {
                let d = Data(bytes: byteData, count: byteData.count)
                try d.write(to: fileURL!)
      
        } catch {
            result(FlutterError(code: "creating_temp_file_failed",
                                message: error.localizedDescription,
                                details: nil)
            )
            return
        }
        self.tempURL = fileURL
        var docPicker: UIDocumentPickerViewController?
        if #available(iOS 14.0, *) {
            docPicker = UIDocumentPickerViewController(forExporting: [fileURL!])
        } else {
            docPicker = UIDocumentPickerViewController(url: fileURL!, in: .exportToService)
        }
        docPicker!.delegate = self
        viewController.present(docPicker!, animated: true, completion: nil)
    }
    
    private func deleteTemp() {
        if tempURL != nil {
            do{ if fileManager.fileExists(atPath: tempURL!.path) {
                try fileManager.removeItem(at: tempURL!)
            }
            tempURL = nil
            
        }
        catch {
            print(error.localizedDescription)
        }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        deleteTemp()
        print("Cancelled")
        result?(nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        deleteTemp()

        print("in didPickDocumentAt " + url.path)
        
        result?(url.path)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        deleteTemp()

        print("in didPickDocumentAt " + urls[0].path)

        result?(urls[0].path)
    }
}
