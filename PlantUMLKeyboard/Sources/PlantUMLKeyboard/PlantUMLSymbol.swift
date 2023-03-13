//
//  PlantUMLSymbol.swift
//  
//
//  Created by Bartolomeo Sorrentino on 14/09/22.
//

import UIKit
import LineEditor
import PlantUMLFramework

public struct Symbol : Decodable, Identifiable, Equatable, Hashable, CustomStringConvertible, LineEditorKeyboardSymbol {
    
    enum CodingKeys: String, CodingKey {
        case id
        case value
        case additionalValues = "additional"
        case type
    }
    
    public var id:String
    private var _value:String?
    public private(set) var additionalValues:[String]?
    public var type = "string"
    
    public var value: String { get { _value ?? id } }
    public var description: String { id }

    static var references: PlantUMLSymbolGroup?
    
    public init( id:String, value:String? = nil, additionalValues: [String]? = nil ) {
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

    // [Regular Expression Capture Groups in Swift](https://www.advancedswift.com/regex-capture-groups/)
    public static  func matchRef( in value: String ) throws -> String? {
        
        let ref_exp = try NSRegularExpression(pattern: #"^#ref\(\s*(?<ref>[\w\d ]+[\w\d]+)\s*\)"#, options: [] )
        
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        
        if let match = ref_exp.firstMatch( in: value, range: range ), let range_in_string = Range( match.range( withName: "ref" ), in: value ) {
            return String( value[range_in_string] )
        }
        
        return nil
        
    }
}

public struct PlantUMLSymbolGroup : Decodable, Identifiable  {
    
    public var id:String { name }
    var name: String
    var rows: [[ Symbol ]]
    
    func first( where predicate: ( Symbol ) -> Bool ) -> Symbol? {
        
        for row in rows.indices {
            
            if let result = rows[row].first(where: predicate ) {
                return result
            }
        }
        
        return nil
    }
}


//// MARK: EQUATABLE COMPLIANCE
//extension Symbol {
//
//    public static func ==(lhs: Symbol, rhs: Symbol) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//// MARK: HASHABLE COMPLIANCE
//extension Symbol {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
