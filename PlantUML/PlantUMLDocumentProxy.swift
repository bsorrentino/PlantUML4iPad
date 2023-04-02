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

class PlantUMLDocumentProxy : ObservableObject, CustomStringConvertible {
    
    @Binding var object: PlantUMLDocument
//    private var items:Array<SyntaxStructure>
    @Published var editorText: String
    @Published  var openAIResult:String = ""

    private(set) var text:String
    
    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    var description: String {
        self.editorText
//        self.items.map { $0.rawValue }.joined( separator: "\n" )
    }
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )

    private var textCancellable:AnyCancellable?
    
    init( document: Binding<PlantUMLDocument> ) {
        self._object = document
        self.text = "@startuml\n\(document.wrappedValue.text)\n@enduml"
        self.editorText = document.wrappedValue.text
//        self.items = Self.buildSyntaxStructureItems( from: contents)
        
        
    }
    
    func setText( _ text: String ) {

        self.text = text
        
//        self.items = Self.buildSyntaxStructureItems( from: text )
    }

    func buildURL() -> URL {
        let script = PlantUMLScript( items: Self.buildSyntaxStructureItems( from: self.text ) )
               
        return presenter.url( of: script )
    }
    
    func reset() {
        self.text = self.object.text
    }
    
    func save() {
        print( "save document")
        self.object.text = self.description
        self.text = "@startuml\n\(object.text)\n@enduml"
    }

    
}


extension PlantUMLDocumentProxy {
    
    public static func buildDocumentText( from text: String ) -> String {
        return text
            .split(whereSeparator: \.isNewline)
            .filter { line in
                line != "@startuml" && line != "@enduml"
            }
            .joined(separator: "\n")
    }

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
