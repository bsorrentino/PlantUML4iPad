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


var plantUMLSymbols:[[Symbol]] = [
    [
        Symbol("title", "title my title"),
        Symbol("header", "header my header"),
        Symbol("footer", "footer my footer"),
        Symbol("autonumber")
    ],
    [
        Symbol("participant","participant \"my participant\" as p1"),
        Symbol("actor", "actor \"my actor\" as a1"),
        Symbol("boundary", "boundary \"my boundary\" as b1"),
        Symbol("control", "control \"my control\" as c1"),
        Symbol("entity", "entity \"my entity\" as e1"),
        Symbol("database", "database \"my database\" as db1"),
        Symbol("collections","collections \"my collections\" as cc1" ),
        Symbol("queue", "queue \"my queue\" as q1")
    ],
    
    [
        Symbol("->x"),
        Symbol("->"),
        Symbol("->>"),
        Symbol("-\\\\"),
        Symbol("\\\\-"),
        Symbol("//--"),
        Symbol("->o"),
        Symbol("o\\\\--"),
        Symbol("<->"),
        Symbol("<->o"),
    ],
    
    [
        Symbol("[#red]"),
        Symbol("note left", "note left /' of participant '/", ["this note is displayed left", "end note"]),
        Symbol("note right", "note right /' of participant '/", ["this note is displayed right", "end note"]),
        Symbol("note over", "note over participant1 /', participant2 '/", ["this note is displayed over participant1", "end note"]),
    ]
    
]

var plantUMLImages:[[UIImage?]] = {
    
    guard let arrows = UIImage(named: "plantuml-sequence-arrows")?.extractTiles( with: CGSize( width: 158.0, height: 28.6) ) else {
        return [ [], [] ,[], [] ]
    }

    return [ [], [], arrows, [] ]
}()
