//
//  PlantUMLDiagramBuilder.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 03/08/22.
//

import Foundation
import PlantUMLFramework

class PlantUMLDiagramObject : ObservableObject, CustomStringConvertible {
    
    @Published var items:Array<SyntaxStructure>

    var description: String {
        self.items.map { $0.rawValue }.joined( separator: "\n" )
    }
    
    let presenter = PlantUMLBrowserPresenter( format: .imagePng )
    
    init( document: PlantUMLDocument ) {
        
        self.items =
            document.text
                .split(whereSeparator: \.isNewline)
                .map { line in
                    SyntaxStructure( rawValue: String(line) )
                }
    }
    
    func buildURL() -> URL {
        let script = PlantUMLScript( items: items )

        return presenter.url( of: script )
    }
    
    
}
