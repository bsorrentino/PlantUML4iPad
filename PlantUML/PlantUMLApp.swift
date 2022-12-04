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
            
            PlantUMLContentView(document: file.$document)
//                .environment(\.editMode, Binding.constant(EditMode.active))
                .environmentObject( PlantUMLDiagramObject( document: file.document))
                
        }
    }
}
