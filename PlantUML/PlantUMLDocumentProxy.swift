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
    @Published var items:Array<SyntaxStructure>
    
    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    var description: String {
        self.items.map { $0.rawValue }.joined( separator: "\n" )
    }
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )

    init( document: Binding<PlantUMLDocument> ) {
        print( "PlantUMLDiagramObject.init" )
        self._object = document
        self.items = document.wrappedValue.text
                        .split(whereSeparator: \.isNewline)
                        .map { line in
                            SyntaxStructure( rawValue: String(line) )
                        }
        self.text = "@startuml\n\(document.wrappedValue.text)\n@enduml"
    }
    
    @Published var text:String
//    func buildInputString() -> String {
//        let text = self.items.map { $0.rawValue }.joined( separator: "\n" )
//        return "@startuml\n\(text)\n@enduml"
//    }
    
    func buildFrom( string: String ) {
        items = string
            .split(whereSeparator: \.isNewline)
            .filter { line in
                line != "@startuml" && line != "@enduml"
            }
            .map { line in
                SyntaxStructure( rawValue: String(line) )
            }
        self.text = string
    }
    
    func buildURL() -> URL {
        let script = PlantUMLScript( items: items )
               
        return presenter.url( of: script )
    }
    
    func save() {
        print( "save document")
        self.object.text = self.description
    }

    
}
