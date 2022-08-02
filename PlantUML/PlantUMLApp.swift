//
//  PlantUMLApp.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI

@main
struct PlantUMLApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: PlantUMLDocument()) { file in
            PalntUMLEditorView(document: file.$document)
        }
    }
}
