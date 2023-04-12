//
//  PlantUMLAppUITests.swift
//  PlantUMLAppUITests
//
//  Created by Bartolomeo Sorrentino on 03/04/23.
//

import XCTest


// table extension
extension XCUIElement {
    

    // [Perform a full swipe left action in UI Tests?](https://stackoverflow.com/a/51639973)
    func longSwipeLeft() {
        let startOffset: CGVector
        let endOffset: CGVector

        startOffset = CGVector(dx: 0.6, dy: 0.0)
        endOffset = CGVector.zero

        let startPoint = self.coordinate(withNormalizedOffset: startOffset)
        let endPoint = self.coordinate(withNormalizedOffset: endOffset)
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
    }
    
}

extension XCUIElementQuery {
    
}


extension XCTestCase {
    
    func waitForNotExistence( element: XCUIElement, timeout: TimeInterval ) {
        let predicate = NSPredicate(format: "exists == FALSE")

        expectation(for: predicate, evaluatedWith: element, handler: nil)

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func waitUntilEnabled( element: XCUIElement, timeout: TimeInterval ) {
        let predicate = NSPredicate(format: "enabled == TRUE")

        let _ = XCTWaiter.wait( for: [ expectation(for: predicate, evaluatedWith: element, handler: nil) ], timeout: timeout )

    }
    
    func wait( reason description: String, timeout: TimeInterval ) {
        let _ = XCTWaiter.wait( for: [ expectation(description: description) ], timeout: timeout )
    }

}
final class PlantUMLAppUITests: XCTestCase {
    

    override func setUpWithError() throws {
// [iOS Localization and Internationalization Testing with XCUITest](https://medium.com/xcblog/ios-localization-and-internationalization-testing-with-xcuitest-495747a74775)
//        let app = XCUIApplication()
//        app.launchArguments += ["-AppleLanguages", "(en)"]
//        app.launchArguments += ["-AppleLocale", "en_US"]
//        app.launch()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindConteMenuDeleteItem() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )

        let predicate = NSPredicate(format: "label beginswith 'Untitled'")
        let query = app.collectionViews.cells.matching(predicate)
        
        XCTAssertTrue(query.element.exists)
        XCTAssertTrue(query.count > 0)

        let e = query.element(boundBy: 0)
        XCTAssertEqual( e.elementType, XCUIElement.ElementType.cell)
        e.press(forDuration: 2.0 )
                
        // [iOS UI testing: element descendants](https://pgu.dev/2020/12/20/ios-ui-tests-element-descendants.html)
        print( "delete: \(app.collectionViews.buttons["Delete"].exists)" )
        print( "elimina: \(app.collectionViews.buttons["Elimina"].exists)" )

    }
    func testOpenAI() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        
        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )

        var predicate = NSPredicate(format: "label beginswith 'Create Document'")
        let cell = app.collectionViews.cells.matching(predicate).element
        
        XCTAssertTrue(cell.exists)
        
        wait( reason: "wait before open diagram", timeout: 3.0 )

        cell.tap()
    
        XCTAssertTrue( app.tables.element.waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["openai"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["editor"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["diagram"].waitForExistence(timeout: 10) )

        app.buttons["diagram"].tap()
        app.buttons["openai"].tap()
        
        // [Sccess TextEditor from XCUIApplication](https://stackoverflow.com/a/69522578/521197)
        XCTAssertTrue( app.textViews["openai_instruction"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["openai_submit"].exists )

        let openaiSubmit = { (instruction:String) in
            
            if let value = app.textViews["openai_instruction"].value as? String, !value.isEmpty {
                XCTAssertTrue( app.buttons["openai_clear"].exists )
                app.buttons["openai_clear"].tap()
            }
            
            app.textViews["openai_instruction"].tap()
            app.textViews["openai_instruction"].typeText( instruction )
                    
            app.buttons["openai_submit"].tap()

            self.waitUntilEnabled(element: app.buttons["openai_submit"], timeout: 30.0)

        }
        
        openaiSubmit( "set title PlantUML meets OpenAI" )
        openaiSubmit( "make simple sequence diagram" )
        openaiSubmit( "sequence representing a microservice invoked using an api key" )
        openaiSubmit( "put in evidence participants" )
        openaiSubmit( "add validation api key" )
        openaiSubmit( "grouping api key validation as security" )
        openaiSubmit( "remove useless (JWT) comment" )

        app.buttons["openai"].tap()

        wait( reason: "wait before exit", timeout: 5.0 )

        app.buttons["editor"].tap()

        XCTAssertTrue( app.buttons["font+"].exists )
        app.buttons["font+"].tap()
        app.buttons["font+"].tap()
        app.buttons["font+"].tap()

        wait( reason: "wait before exit", timeout: 5.0 )

        // [How to access back bar button item in universal way under UITests in Xcode?](https://stackoverflow.com/a/38595332/521197)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // delete document
        predicate = NSPredicate(format: "label beginswith 'Untitled'")
        let query = app.collectionViews.cells.matching(predicate)
            
        XCTAssertTrue(query.element.exists)
        
        for _ in 0..<query.count {
            let e = query.element(boundBy: 0)
            XCTAssertEqual( e.elementType, XCUIElement.ElementType.cell)
            e.press(forDuration: 2.0 )
            
            XCTAssertTrue( app.collectionViews.buttons["Delete"].exists )
            app.collectionViews.buttons["Delete"].tap()
        }

        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    
//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
