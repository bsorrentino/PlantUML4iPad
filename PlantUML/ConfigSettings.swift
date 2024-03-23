//
//  Constants.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 22/03/24.
//

import Foundation

fileprivate func makeBool( _ value: Any? ) -> Bool {
    guard let asString = value as? NSString else {
        return false
    }
    
    return asString.boolValue

}

let SAVE_DRAWING_IMAGE = makeBool(Bundle.main.object(forInfoDictionaryKey: "SAVE_DRAWING_IMAGE"))

let DEMO_MODE = makeBool(Bundle.main.object(forInfoDictionaryKey: "DEMO_MODE"))
