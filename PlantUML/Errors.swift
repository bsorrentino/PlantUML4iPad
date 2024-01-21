//
//  File.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 21/01/24.
//

import Foundation

enum Errors: Error {
    case readingPromptError(String)
    
    public var localizedDescription: String {
        if case .readingPromptError(let message) = self {
            return message
        }
        return "generic error"
    }
}
