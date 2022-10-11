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
        "hide footbox"
    }
    
    Symbol.Line {
        ("box", "box \"\\nmy box\\n", ["end box"])
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
        ("group",  "group My own label", ["end"] )
        ("loop",  "loop N times", ["end"] )
        ("alt", "alt successful case", [ "else some kind of failure", "end"] )
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
            ("actor", "actor \"my actor\" as ac1")
            ("agent", "agent \"my agent\" as ag1")
            ("artifact", "artifact \"my artifact\" as ar1")
            ("boundary", "boundary \"my boundary\" as bn1")
            ("card", "card \"my card\" as cd1")
            ("circle", "circle \"my circle\" as cr1")
            ("cloud", "cloud \"my cloud\" as cd1")
            ("collections", "collections \"my collections\" as cl1")
            ("component", "component \"my component\" as cp1")
            ("control", "control \"my control\" as cn1")
            ("person", "person \"my person\" as pr1")
            ("queue", "queue \"my queue\" as qq1")
            ("rectangle", "rectangle \"my rect\\n\" as rc1 {", ["}"])
        }
        
        Symbol.Line {
            ("database", "database  \"my database\" as db1")
            ("entity", "entity \"my entity\" as ee1")
            ("file", "file \"my file\" as ff1")
            ("folder", "folder \"my folder\" as fl1")
            ("frame", "frame \"my frame\" as fr1")
            ("hexagon", "hexagon \"my hexagon\" as hx1")
            ("interface", "interface \"my interface\" as if1")
            ("label", "label \"my label\" as lb1")
            ("node", "node \"my node\" as nd1")
            ("package", "package \"my package\" as pc1")
            ("stack", "stack \"my stack\" as sk1")
            ("storage", "storage \"my storage\" as st1")
            ("usecase", "usecase \"my usecase\" as uc1")
        }
        
        Symbol.Line {
            "--"
            ".."
            "~~"
            "=="
            "-->"
            "--*"
            "--o"
            "--+"
            "--#"
            "-->>"
            "--0"
            "--^"
            "--(0"
            "-(0-"
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

    

