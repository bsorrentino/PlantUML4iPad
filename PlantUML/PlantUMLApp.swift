//
//  PlantUMLApp.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI

@main
struct PlantUMLApp: App {
   
    init() {
        URLCache.shared.memoryCapacity = 10_000_000 // ~10 MB memory space
        URLCache.shared.diskCapacity = 100_000_000 // ~1GB disk cache space
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: PlantUMLDocument()) { file in
            if #available(iOS 16, *) {
                PlantUMLContentView(document: file.$document,
                                    diagram: PlantUMLDocumentProxy( document: file.document) )
                    // [Document based app shows 2 back chevrons on iPad](https://stackoverflow.com/a/74245034/521197)
                    .toolbarRole(.navigationStack)
            }
            else {
                PlantUMLContentView(document: file.$document,
                                    diagram: PlantUMLDocumentProxy( document: file.document))
            }
        }
    }
}
