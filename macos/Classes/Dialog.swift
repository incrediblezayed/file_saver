//
//  Dialog.swift
//  file_saver
//
//  Created by Hassan Ansari on 23/06/21.
//

import Foundation

extension NSSavePanel {
    func openDialog(){
        runModal()
    }
}

class Dialog {
func openSaveAsDialog(params: Params){
    let panel = NSSavePanel()
    panel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    panel.nameFieldStringValue = params.fileName!+"."+params.ext!
    panel.level = .modalPanel
    panel.runModal()
    }
}
