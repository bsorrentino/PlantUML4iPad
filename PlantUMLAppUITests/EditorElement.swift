//
//  EditorElement.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 22/03/24.
//

import XCTest


struct EditorElement {
    
    var element:XCUIElement
    
    init( app: XCUIApplication ) {
        
        if( app.webViews.textViews.element.waitForExistence(timeout: 5.0) ) {
            
            XCTAssertEqual( app.webViews.textViews.count, 1 )
            element = app.webViews.textViews.element(boundBy: 0)
            
            return
        }
        
        XCTAssertTrue(app.webViews.textFields.element.waitForExistence(timeout: 5.0))
        XCTAssertEqual( app.webViews.textFields.count, 1 )

        element = app.webViews.textFields.element(boundBy: 0)
    }
    
    func typeText(_ str:String) {
        str.forEach { char in
            element.typeText( "\(char)" )
        }
    }

    func typeText( andDismissIntellisense str: String  ) {
        typeText( str )
        let coordinate = element.coordinate(withNormalizedOffset: CGVector( dx: 300, dy: 0))
        coordinate.tap()
    }

    func typeText( andSelectIntellisense str:String, then: (() -> Void)? = nil ) {
        typeText( str )
        typeText("\t")
        then?()
    }
}
