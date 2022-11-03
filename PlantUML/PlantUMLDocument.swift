//
//  PlantUMLDocument.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var umldiagram: UTType {
        // UTType(importedAs: "com.example.plain-text")
        UTType(importedAs: "org.bsc.plantuml-text")
    }
}

struct PlantUMLDocument: FileDocument {
    var text: String
    
    init(text: String = "Title untitled") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.umldiagram] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
