//
//  DrawingUITests.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 23/03/24.
//

import XCTest

final class DrawingUITests: XCTestCase {

    var app: XCUIApplication?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func findDocument( _ app: XCUIApplication, withTitle title: String ) -> XCUIElement {
        let predicate = NSPredicate(format: "label beginswith '\(title)'")
        let query = app.collectionViews.cells.matching(predicate)
        
        XCTAssertTrue( query.element.waitForExistence(timeout: 5.0) )
        XCTAssertEqual( query.count, 1, "There are more 'TEST' document available!" )
        
        return query.element(boundBy: 0)

    }
    
    func testDrawDiagram() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launch()

        let document = findDocument( app, withTitle: "TEST")
        
        document.tap()
        
        XCTAssertTrue( app.buttons["openai"].waitForExistence(timeout: 10) )
        
        app.buttons["openai"].tap()
        
        XCTAssertTrue( app.buttons["openai_drawing"].waitForExistence(timeout: 10) )
        
        app.buttons["openai_drawing"].tap()

        XCTAssertTrue( app.buttons["drawing_tools"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["drawing_process"].exists )

        app.buttons["drawing_tools"].tap()

        wait(reason: "Wait for drawing graph", timeout: 20 )
        
        app.buttons["drawing_process"].tap()
        
        wait(reason: "Wait for process drawing", timeout: 30 )
        XCTAssertTrue( app.buttons["diagram_preview"].waitForExistence(timeout: 60) )
        
        app.buttons["diagram_preview"].tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
