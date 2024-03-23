//
//  PlantUMLApp.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI

/// [How to let the app know if it's running Unit tests in a pure Swift project](https://stackoverflow.com/a/63447524/521197))
var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["NO_TEST_RUNNING"] == nil
}


func getFileName( _ file: FileDocumentConfiguration<PlantUMLDocument>, default def: String ) -> String {
    file.fileURL?.deletingPathExtension().lastPathComponent ?? def
}

@main
struct PlantUMLApp: App {
   
    init() {
        URLCache.shared.memoryCapacity = 10_000_000 // ~10 MB memory space
        URLCache.shared.diskCapacity = 100_000_000 // ~1GB disk cache space
        
        // Config Settings
        print( "DEMO_MODE: \(DEMO_MODE)" )
        print( "SAVE_DRAWING_IMAGE: \(SAVE_DRAWING_IMAGE)" )
        let documentDir = try? FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: false)
        print( "DOCUMENT DIRECTORY\n\(String(describing: documentDir))")
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: PlantUMLDocument()) { file in                
            
            PlantUMLDocumentView( document: PlantUMLObservableDocument( document: file.$document,
                                                                        fileName: getFileName(file, default: "Untitled" )))
            // [Document based app shows 2 back chevrons on iPad](https://stackoverflow.com/a/74245034/521197)
            .toolbarRole(.navigationStack)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}
