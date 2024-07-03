//
//  Constants.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 22/03/24.
//

import Foundation



@inline(__always) func readConfigString( forInfoDictionaryKey key: String ) -> String? {
    Bundle.main.object(forInfoDictionaryKey: key) as? String
}

func readConfigBool( forInfoDictionaryKey key: String ) -> Bool {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? NSString else {
        return false
    }
    return value.boolValue
}

let DEMO_MODE = readConfigBool(forInfoDictionaryKey: "DEMO_MODE")
let SAVE_DRAWING_IMAGE = readConfigBool(forInfoDictionaryKey: "SAVE_DRAWING_IMAGE")

