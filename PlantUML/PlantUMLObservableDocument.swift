//
//  PlantUMLDiagramBuilder.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 03/08/22.
//


import Foundation
import PlantUMLFramework
import Combine
import SwiftUI


class DebounceRequest {

    private var requestSubject = PassthroughSubject<Void, Never>()
    
    public let publisher:AnyPublisher<Void,Never>

    init( debounceInSeconds seconds: Double ) {
        
        publisher = requestSubject
            .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            .eraseToAnyPublisher()

    }
    
    func send() {
        requestSubject.send(())
    }
}

class PlantUMLObservableDocument : ObservableObject {
    
    @Binding var object: PlantUMLDocument
    @Published var text: String
    var drawing: Data? 
//    {
//        didSet {
//            print( "update drawing!" )
//            if DEMO_MODE {
//                saveDrawingForDemo()
//            }
//        }
//    }
    var fileName:String

    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    private var textCancellable:AnyCancellable?
    
    init( document: Binding<PlantUMLDocument>, fileName:String ) {
        self._object = document
        self.text = document.wrappedValue.isNew ? "title Untitled" : document.wrappedValue.text
        self.fileName = fileName
        self.drawing = document.wrappedValue.drawing
//        if DEMO_MODE {
//            self.drawing = loadDrawingForDemo(fromDocument: document.wrappedValue )
//        }
//        else {
//            self.drawing = document.wrappedValue.drawing
//        }
    }
    
    func buildURL() -> URL {
        
        let items = text
                        .split(whereSeparator: \.isNewline)
                        .map { line in
                            SyntaxStructure( rawValue: String(line) )
                        }
        let script = PlantUMLScript( items: items )
               
        return plantUMLUrl( of: script, format: .imagePng )
    }
    
    func reset() {
        self.text = self.object.text
        self.drawing = self.object.drawing
    }
    
    func save() {
        print( "save document")
        self.object.text = self.text
        self.object.drawing = self.drawing
    }

    
}


extension PlantUMLObservableDocument {
    
    private static func buildSyntaxStructureItems( from text: String ) -> Array<SyntaxStructure> {
        return text
            .split(whereSeparator: \.isNewline)
            .filter { line in
                line != "@startuml" && line != "@enduml"
            }
            .map { line in
                SyntaxStructure( rawValue: String(line) )
            }
    }

}

// MARK: DEMO
extension PlantUMLObservableDocument {
    
    fileprivate func saveDrawingForDemo() {
        guard let data = self.drawing else {
            return
        }
        
        do {
            let dir = try FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let fileURL = dir.appendingPathComponent("drawing.bin")
            try data.write(to: fileURL)
            print( "saved drawing file\n\(fileURL)")
        }
        catch {
            print( "error saving file \(error.localizedDescription)" )
        }
        
    }
    
    fileprivate func loadDrawingForDemo( fromDocument doc: PlantUMLDocument) -> Data? {
        
        guard doc.drawing == nil else {
            return doc.drawing
        }

        do {
            let dir = try FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let fileURL = dir.appendingPathComponent("drawing.bin")
            
            return try Data(contentsOf: fileURL)
        }
        catch {
            print( "error loading drawing file \(error.localizedDescription)" )
        }

        return nil
    }

}
