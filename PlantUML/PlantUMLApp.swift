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

@main
struct PlantUMLApp: App {
   
    init() {
        URLCache.shared.memoryCapacity = 10_000_000 // ~10 MB memory space
        URLCache.shared.diskCapacity = 100_000_000 // ~1GB disk cache space
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: PlantUMLDocument()) { file in                
            PlantUMLDocumentMenu( doc: file.$document )
        }
    }
}
