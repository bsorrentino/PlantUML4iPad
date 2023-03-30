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
    @Published var text:String
    
    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    var description: String {
        self.items.map { $0.rawValue }.joined( separator: "\n" )
    }
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )

    private var textCancellable:AnyCancellable?
    
    init( document: Binding<PlantUMLDocument> ) {
        let contents = "@startuml\n\(document.wrappedValue.text)\n@enduml"
        self._object = document
        self.text = contents
        self.items = Self.itemsFromText(contents)
        
        self.textCancellable = self.$text.sink {
            self.items = Self.itemsFromText($0)
        }
    }
    
    func buildURL() -> URL {
        let script = PlantUMLScript( items: items )
               
        return presenter.url( of: script )
    }
    
    /**
        set current text with original document text
     */
    func reset() {
        self.text = self.object.text
    }
    func save() {
        print( "save document")
        self.object.text = self.description
    }

    
}


extension PlantUMLDocumentProxy {
    
    private static func itemsFromText( _ text: String ) -> Array<SyntaxStructure> {
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
