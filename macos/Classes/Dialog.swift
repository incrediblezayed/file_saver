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

class Dialog: NSSavePanel {
    

    
    func openSaveAsDialog(params: Params){
    
             self.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
             self.nameFieldStringValue = params.fileName!+"."+params.ext!
             self.level = .modalPanel
             self.runModal()
    
    

        
//        let i = panel.runModal()
//
//            if i.rawValue == NSApplication.ModalResponse.OK.rawValue {
//
//            }
        
    }
}
