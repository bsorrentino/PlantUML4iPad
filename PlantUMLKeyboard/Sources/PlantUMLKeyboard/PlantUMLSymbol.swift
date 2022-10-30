//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 14/09/22.
//

import UIKit
import LineEditor

struct Symbol : Decodable, Identifiable, CustomStringConvertible, LineEditorKeyboardSymbol {

    enum CodingKeys: String, CodingKey {
            case id
            case value = "v0"
            case additionalValues = "v1"
        }
     var description: String { value }

     var id:String
     private var _value:String?
     private var _additionalValues:[String]?

     var value: String {
         get { _value ?? id }
     }

     var additionalValues: [String]? {
         get { _additionalValues }
     }

     init( _ id:String, _ value:String? = nil, _ additionalValues: [String]? = nil) {
         self.id = id
         self._value = value
         self._additionalValues = additionalValues
     }
    
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self )
        
        self.id = try container.decode(String.self, forKey: CodingKeys.id)
        self._value = try container.decodeIfPresent(String.self, forKey: CodingKeys.value)
        self._additionalValues = try container.decodeIfPresent([String].self, forKey: CodingKeys.additionalValues)

    }

}


struct PlantUMLSymbolGroup : Decodable, Identifiable  {

    var id:String {
        name
    }
    var name: String
    var rows: [[ Symbol ]]
}


    

