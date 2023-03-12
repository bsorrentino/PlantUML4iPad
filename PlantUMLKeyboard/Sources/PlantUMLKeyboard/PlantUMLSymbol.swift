//
//  PlantUMLSymbol.swift
//  
//
//  Created by Bartolomeo Sorrentino on 14/09/22.
//

import UIKit
import LineEditor

public struct Symbol : Decodable, Identifiable, CustomStringConvertible, LineEditorKeyboardSymbol {

    enum CodingKeys: String, CodingKey {
            case id
            case value
            case additionalValues = "additional"
            case type
        }
     public var description: String { value }

     public var id:String
     private var _value:String?
     public private(set) var additionalValues:[String]?
     public var type = "string"

     public var value: String {
         get { _value ?? id }
     }

//     var additionalValues: [String]? {
//         get { _additionalValues }
//     }

     public init( id:String, value:String? = nil, additionalValues: [String]? = nil) {
         self.id = id
         self._value = value
         self.additionalValues = additionalValues
     }
    
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self )
        
        self.id = try container.decode(String.self, forKey: CodingKeys.id)
        self._value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
        self.additionalValues = try container.decodeIfPresent([String].self, forKey: CodingKeys.additionalValues)
        if let type = try container.decodeIfPresent(String.self, forKey: CodingKeys.type) {
            self.type = type
        }

    }

}


struct PlantUMLSymbolGroup : Decodable, Identifiable  {

    var id:String {
        name
    }
    var name: String
    var rows: [[ Symbol ]]
}


    

