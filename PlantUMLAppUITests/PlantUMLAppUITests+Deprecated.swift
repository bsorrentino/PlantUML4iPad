//
//  PlantUMLAppUITests+Deprecated.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 23/03/24.
//

import Foundation
import XCTest

/// Deprecated
extension PlantUMLAppUITests {
    
    func getPlantUMLKeyboard( _ app: XCUIApplication, handler: (( ( customKeyboard: XCUIElement, addBelow: XCUIElement, addAbove: XCUIElement ) ) -> Void)  ) -> Void {

        XCTAssertTrue(app.buttons["PlantUML Keyboard"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.buttons["Add Below"].exists)
        XCTAssertTrue(app.buttons["Add Above"].exists)
        
        handler( (
            customKeyboard: app.buttons["PlantUML Keyboard"],
            addBelow: app.buttons["Add Below"],
            addAbove: app.buttons["Add Above"]
        ))

    }
    
    
    func selectChoice(  _ app: XCUIApplication, ofTab tab: String, forKey key: String, value choice: String  ) {
        
        XCTAssertTrue(app.buttons[tab].exists)
        XCTAssertTrue(app.buttons[tab].isSelected)

        app.buttons[key].tap()
        
        let choiceView = app.descendants(matching: .other).matching(identifier: "choiceview" ).element
        XCTAssertTrue(choiceView.exists)
        
        let choiceCells = choiceView.descendants(matching: .cell)
        XCTAssertEqual(choiceCells.count, 12)
        
        let choiceSelected = [0..<choiceCells.count].map { r in
            choiceCells.element(boundBy: r.startIndex).staticTexts.element(boundBy: 0)
        }
        .first( where: { $0.label == choice })

        XCTAssertNotNil(choiceSelected)

        choiceSelected?.tap()
 
    }
    
    func selectColor(  _ app: XCUIApplication, ofTab tab: String, forKey key: String, value choice: String  ) {
        
        XCTAssertTrue(app.buttons[tab].exists)
        XCTAssertTrue(app.buttons[tab].isSelected)

        // app.buttons[key].tap()
        
        let d = app.descendants(matching: .other)
        for i in 0..<d.count {
            
            let e = d.element(boundBy: i)
            if e.exists {
                print( "element[\(i)].id[\(e.title)]" )

            }
        }
         
    }

    func testPlantUMLKeyboard() throws {

        self.app = XCUIApplication()
        
        guard let app else { XCTFail( "error creating XCUIApplication instance") ; return }

        app.launch()

        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )
        
        openNewFile(app)
    
        XCTAssertTrue( app.buttons["editor"].exists )
        XCTAssertTrue( app.buttons["diagram"].exists )

        app.buttons["editor"].tap()
        
        XCTAssertEqual( app.tables.cells.count, 1 )

        getCellTextField(table: app.tables.element, atRow: 0 ) { textField in

            textField.tap()
            XCTAssertEqual( textField.valueAsString(), "Title untitled")

        }
        
        getPlantUMLKeyboard( app ) { (customKeyboard, _, addAbove) in
        
            addAbove.tap()
       
            XCTAssertEqual( app.tables.cells.count, 2 )

            customKeyboard.tap()

            XCTAssertTrue(app.buttons["general"].waitForExistence(timeout: 3.0))
            XCTAssertTrue(app.buttons["sequence"].exists)

        }

        selectColor( app, ofTab: "general", forKey: "#color", value: "")

        selectChoice( app, ofTab: "general", forKey: "skinparam", value: "linetype ortho")
                
        let _ = getCellTextField(table: app.tables.element, atRow: 1 ) { textField in
            textField.tap()
        }
                
        // XCTAssertTrue(app.buttons["dismiss"].exists)
        // app.buttons["dismiss"].tap()
        
        getPlantUMLKeyboard( app ) { ( customKeyboard, addBelow, _ ) in

            addBelow.tap()

            customKeyboard.tap()
            if !app.buttons["general"].waitForExistence(timeout: 0.5) { // FIX SHOW KEYBOARD BUG
                customKeyboard.tap()
            }

        }
        
        XCTAssertTrue(app.buttons["general"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.buttons["sequence"].exists)

        app.buttons["sequence"].tap()

        XCTAssertTrue(app.buttons["hide footbox"].exists)
        
        app.buttons["hide footbox"].tap()
        
        
    }

}
