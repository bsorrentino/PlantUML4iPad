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
        UTType(importedAs: "org.bsc.plantuml-text")
    }
}

fileprivate struct Content {
    let text: String
    let drawing: Data?

    private enum CodingKeys: String, CodingKey {
        case text
        case drawing // = "image" // Optional name change for clarity (optional)
    }

}

// Encodable Exension
extension Content : Encodable {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        
//        guard let textUTF8 = text.data(using: .utf8) else {
//            throw Errors.documentEncodeError("Cannot convert text in utf8")
//        }
        
        try container.encode(text, forKey: .text)
        if let drawing {
            try container.encode(drawing.base64EncodedString(), forKey: .drawing)
        }
//        try container.encodeIfPresent(drawing, forKey: .drawing)
    }

}

// Decodable Extension
extension Content : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)

        if let base64String = try container.decodeIfPresent(String.self, forKey: .drawing) {
            if let data = Data(base64Encoded: base64String) {
                drawing = data
            } else {
                throw Errors.documentDecodeError("Invalid base64 string")
            }
        } else {
            drawing = nil
        }
    }
}

struct PlantUMLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.umldiagram] }

    var text: String
    var drawing: Data?
    
    var isNew:Bool {
        text.isEmpty
    }
    
    init( text:String = "") {
        self.text = text 
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw Errors.documentDecodeError("error getting regularFileContents ")
        }
        
        text = ""
        
        do {
            let decoder = JSONDecoder()
            
            let content = try decoder.decode(Content.self, from: data)
        
            text = content.text
            drawing = content.drawing
        }
        catch { // Backward compatibility
            if let string = String(data: data, encoding: .utf8) { // Backward compatibility
                text = string
            }
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        
        let encoder = JSONEncoder()
        let content = Content(text: text, drawing: drawing)
        let data = try encoder.encode(content)
        return .init(regularFileWithContents: data)
    }
}
