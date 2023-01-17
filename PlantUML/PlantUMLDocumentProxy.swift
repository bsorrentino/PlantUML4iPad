//
//  PlantUMLDiagramBuilder.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 03/08/22.
//

import Foundation
import PlantUMLFramework
import Combine


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
    
    @Published var items:Array<SyntaxStructure>
    
    let updateRequest = DebounceRequest( debounceInSeconds: 0.5)
    
    var description: String {
        self.items.map { $0.rawValue }.joined( separator: "\n" )
    }
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )

    init( text: String ) {
        print( "PlantUMLDiagramObject.init" )
        self.items =
            text
                .split(whereSeparator: \.isNewline)
                .map { line in
                    SyntaxStructure( rawValue: String(line) )
                }
        
    }
    
    convenience init( document: PlantUMLDocument ) {
        
        self.init(text: document.text )
    }
    
    func buildURL() -> URL {
        let script = PlantUMLScript( items: items )
               
        return presenter.url( of: script )
    }
    
    
}
