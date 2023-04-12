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

class PlantUMLDocumentProxy : ObservableObject {
    
    @Binding var object: PlantUMLDocument
    @Published var text: String
    
    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )

    init( document: Binding<PlantUMLDocument> ) {
        self._object = document
        self.text = document.wrappedValue.text
    }
    
    func buildURL() -> URL {
        
        let items = text
                        .split(whereSeparator: \.isNewline)
                        .map { line in
                            SyntaxStructure( rawValue: String(line) )
                        }
        let script = PlantUMLScript( items: items )
               
        return presenter.url( of: script )
    }
    
    func save() {
        print( "save document")
        self.object.text = self.text
    }

    
}
