//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 14/09/22.
//

import UIKit

struct Symbol : Identifiable, CustomStringConvertible {
    var description: String {
        return id
    }
    
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
    
}

//
// MARK: COMMON DIAGRAMS
//

@Symbol.LineBuilder
fileprivate func _common_symbols() -> [[Symbol]] {
    
    Symbol.Line {
        ("title", "title my title")
        ("header", "header my header")
        ("footer", "footer my footer")
    }
    
    Symbol.Line {
        ("allow mixing", "allow_mixing")
        "hide empty members"
        ("shadowing false", "skinparam shadowing false")
        ("linetype ortho", "skinparam linetype ortho")
        ("left to right", "left to right direction")
        ("top to bottom", "top to bottom direction")
    }
    
    Symbol.Line {
        "[#red]"
        "#line.dashed"
    }

}

fileprivate let common_symbols = {
    _common_symbols()
}()

//
// MARK: SEQUENCE DIAGRAMS
//

@Symbol.LineBuilder
fileprivate func _sequence_symbols() -> [[Symbol]] {
    
    Symbol.Line {
        "autonumber"
    }
    
    Symbol.Line {
        ("actor", "actor \"my actor\" as a1")
        ("participant","participant \"my participant\" as p1")
        ("boundary", "boundary \"my boundary\" as b1")
        ("control", "control \"my control\" as c1")
        ("entity", "entity \"my entity\" as e1")
        ("database", "database \"my database\" as db1")
        ("collections","collections \"my collections\" as cc1" )
        ("queue", "queue \"my queue\" as q1")
    }
    
    Symbol.Line {
        "->x"
        "->"
        "->>"
        "-\\\\"
        "\\\\-"
        "//--"
        "->o"
        "o\\\\--"
        "<->"
        "<->o"
        
    }
    
    Symbol.Line {
        "[#red]"
        ("note left", "note left /' of p1 '/", ["this note is displayed left", "end note"])
        ("note right", "note right /' of p1 '/", ["this note is displayed right", "end note"])
        ("note over", "note over p1 /', p2 '/", ["this note is displayed over participant1", "end note"])
    }
}

fileprivate let sequence_symbols = {
    _sequence_symbols()
}()

fileprivate let sequence_images:[[UIImage?]] = {
    
    var arrows:[UIImage?] = []
    
    if let img = UIImage(named: "plantuml-sequence-arrows", in: .module, compatibleWith: nil)  {
        arrows = img.extractTiles( with: CGSize( width: 158.0, height: 28.6) )
    }
    
    return [ [], [], arrows, [] ]
}()

//
// MARK: DEPLOYMENT DIAGRAMS
//


@Symbol.LineBuilder
fileprivate func _deployment_symbols() -> [[Symbol]] {
    
        Symbol.Line {
            "actor"
            "agent"
            "artifact"
            "boundary"
            "card"
            "circle"
            "cloud"
            "collections"
            "component"
            "control"
            "person"
            "queue"
            ("rectangle", "rectangle \"Rect1\\n\" as r1 {", ["}"])
        }
        
        Symbol.Line {
            ("database", "database db1")
            "entity"
            "file"
            "folder"
            "frame"
            "hexagon"
            "interface"
            "label"
            "node"
            "package"
            "stack"
            "storage"
            "usecase"
        }
        
        Symbol.Line {
            "#line.dashed"
            "#line.dotted"
        }
    
}

fileprivate var deployment_symbols = {
    _deployment_symbols()
}()

//
// MARK: SYMBOL GROUPS
//
enum PlantUMLSymbolGroup : String, CaseIterable {
    case common = "Commons"
    case sequence = "Sequence"
    case deployment = "Deployment"
        
    var symbols: [[ Symbol ]] {
        switch self {
        case .common:
             return  common_symbols
        case .sequence:
             return sequence_symbols
        case .deployment:
            return deployment_symbols
        }
    }

    var images: [[ UIImage? ]] {
        switch self {
        case .sequence:
             return  [] // sequence_images
        default:
             return []
         }
    }
}

    

