//
//  XCUIElement+TextField.swift
//  PlantUMLAppUITests
//
//  Created by Bartolomeo Sorrentino on 05/04/23.
//

import XCTest

// MARK: Text Field Extension
extension XCUIElement {
    
    func valueAsString() -> String? {
        self.value as? String
    }
    
    func typeBackspace( times: Int ) {

        if let _ = self.value as? String {
            
            for _ in 1...times {
                self.typeText( XCUIKeyboardKey.delete.rawValue )
            }
        }

    }
    
    func clearText() {
        
        if let s = self.value as? String {
            
            s.forEach { _ in
                self.typeText( XCUIKeyboardKey.delete.rawValue )
            }
        }
        
    }

}

