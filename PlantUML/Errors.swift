//
//  File.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 21/01/24.
//

import Foundation

enum Errors: Error {
    case readingPromptError(String)
    case documentDecodeError(String)
    case documentEncodeError(String)
    
    public var localizedDescription: String {
        switch(self) {
        case .readingPromptError(let message):
            message
        case .documentDecodeError(let message):
            message
        case .documentEncodeError(let message):
            message
//        default:
//            "generic error"
        }
    }
}
