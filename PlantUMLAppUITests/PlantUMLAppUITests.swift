//
//  PlantUMLAppUITests.swift
//  PlantUMLAppUITests
//
//  Created by Bartolomeo Sorrentino on 03/04/23.
//

import XCTest



final class PlantUMLAppUITests: XCTestCase {
    
    var app: XCUIApplication?
    
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
        
        guard let app else { return }
        
        wait( reason: "wait before exit", timeout: 5.0 )

        // [How to access back bar button item in universal way under UITests in Xcode?](https://stackoverflow.com/a/38595332/521197)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // delete document
        let predicate = NSPredicate(format: "label beginswith 'Untitled'")
        let query = app.collectionViews.cells.matching(predicate)
            
        XCTAssertTrue( query.element.waitForExistence(timeout: 5.0) )
        
        for _ in 0..<query.count {
            let e = query.element(boundBy: 0)
            XCTAssertEqual( e.elementType, XCUIElement.ElementType.cell)
            e.press(forDuration: 2.0 )
            
            XCTAssertTrue( app.collectionViews.buttons["Delete"].exists )
            app.collectionViews.buttons["Delete"].tap()
        }
        
        self.app = nil
    }

    func findConteMenuDeleteItem() throws {
        // UI tests must launch the application that they test.
        self.app = XCUIApplication()
        
        guard let app else { XCTFail( "error creating XCUIApplication instance") ; return }
        
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
        XCTAssertTrue( app.collectionViews.buttons["Delete"].exists )

    }
    
    func openNewFile( _ app: XCUIApplication ) {
        
        // wait( reason: "wait before open diagram", timeout: 1.0 )

        let predicate = NSPredicate(format: "label beginswith 'Create Document'")
        let cell = app.collectionViews.cells.matching(predicate).element
        
        XCTAssertTrue(cell.waitForExistence(timeout: 3.0))
        
        cell.tap()
        
        XCTAssertTrue( app.webViews.element.waitForExistence(timeout: 10) )

    }

    func __testCopyAndPasteDiagram() {
        // UI tests must launch the application that they test.
        self.app = XCUIApplication()
        
        guard let app else { XCTFail( "error creating XCUIApplication instance") ; return }


        UIPasteboard.general.string =
                """
                
                Bob -> Alice : Authentication Request
                Bob <- Alice : Authentication Response
                
                """
        
        
        app.launch()

        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )
        
        openNewFile(app)
    
        XCTAssertTrue( app.buttons["editor"].exists )
        XCTAssertTrue( app.buttons["diagram"].exists )

        app.buttons["editor"].tap()
        
        XCTAssertEqual( app.tables.cells.count, 1 )

        getCellTextField( table: app.tables.element, atRow: 0 ) { textField in
            
            XCTAssertEqual(textField.valueAsString(), "Title untitled" )
            
            textField.tap()

            let paste = app.menuItems["Paste"]

            let lastCharCursor = textField.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.0))
            lastCharCursor.tap()

            XCTAssertTrue(paste.exists)

            paste.tap()
            
            XCTAssertEqual(textField.valueAsString(), "Title untitled")
            
        }

        XCTAssertEqual( app.tables.cells.count, 4 )
    }
    
    func testSequenceDiagram() throws {
        // UI tests must launch the application that they test.
        self.app = XCUIApplication()
        
        guard let app else { XCTFail( "error creating XCUIApplication instance") ; return }

        app.launch()

        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )

        openNewFile(app)
    
        XCTAssertTrue( app.buttons["editor"].exists )
        XCTAssertTrue( app.buttons["diagram"].exists )

        app.buttons["editor"].tap()
        
        
        
        let editor = EditorElement(app: app)
        
        editor.element.tap()
        wait( reason: "wait before tap again", timeout: 0.5 )
        editor.element.tap()

        XCTAssertTrue( app.staticTexts["editor-text"].exists )
        XCTAssertEqual( app.staticTexts["editor-text"].label, "Title untitled")
        
        editor.element.typeBackspace( times: 8 )
        editor.typeText( "My Diagram" )
        
        editor.typeText( andSelectIntellisense: "\nfootbox" )
//        typeTextAndDismissIntellisense( "\nautoactivate on" )
        
        editor.typeText( andSelectIntellisense: "\n\nacto") {
            // move cursor to previous line
            var coordinate = editor.element.coordinate(withNormalizedOffset: CGVector( dx: 20, dy: -1))
            coordinate.press(forDuration: 0.7) // simulate text selection
            
            editor.typeText( "User") // replace text
            
            coordinate = editor.element.coordinate(withNormalizedOffset: CGVector( dx: 30, dy: -1))
            coordinate.press(forDuration: 0.7) // simulate text selection
            
            editor.typeText( "The User") // replace text
            
            
            // move cursor to next line
            coordinate = editor.element.coordinate(withNormalizedOffset: CGVector( dx: 0, dy: 1))
            coordinate.tap()
        }
                
        editor.typeText( andDismissIntellisense: "\nparticipant P1")

        editor.typeText( andSelectIntellisense: "\npartic") {
            
            editor.typeText( andDismissIntellisense:" P2")
        }
    
        editor.typeText( andDismissIntellisense: "\n\nUser --> P1 : call method 1")
        
        editor.typeText( """
        
        activate P1
        
        P1 --> P2

        activate P2
        
        P2 --> P2 : do something
        
        """)
        
        editor.typeText( andDismissIntellisense: "\nreturn")

        editor.typeText( andDismissIntellisense: "\n\nreturn: computation result")

        app.buttons["diagram"].tap()

        wait( reason: "wait before back to diagram", timeout: 5.0 )

    }

    func __testActivityDiagram() throws {
        // UI tests must launch the application that they test.
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
            
            textField.typeBackspace(times: 8)
            XCTAssertEqual( textField.valueAsString(), "Title ")
            
            textField.typeText( "activity diagram\n")
            XCTAssertEqual( textField.valueAsString(), "Title activity diagram")
        }

       
        XCTAssertEqual( app.tables.cells.count, 2 )

        """
        start
        if (condition A) then (yes)
          :Text 1;
        elseif (condition B) then (yes)
          :Text 2;
          stop
        (no) elseif (condition C) then (yes)
          :Text 3;
        (no) elseif (condition D) then (yes)
          :Text 4;
        else (nothing)
          :Text else;
        endif
        stop
        """.split(whereSeparator: \.isNewline).forEach { value in
            
            let nextText = app.tables.cells.count - 1
            
            getCellTextField(table: app.tables.element, atRow: nextText ) { textField in
                textField.tap()
                textField.typeText( "\(value)\n")
            }
            
        }
        
        app.buttons["diagram"].tap()
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    
    func testOpenAI() throws {
        self.app = XCUIApplication()
        
        guard let app else { XCTFail( "error creating XCUIApplication instance") ; return }

        app.launch()

            
        XCTAssertTrue(  app.collectionViews.element.waitForExistence(timeout: 10) )

        let predicate = NSPredicate(format: "label beginswith 'Create Document'")
        let cell = app.collectionViews.cells.matching(predicate).element
        
        XCTAssertTrue(cell.exists)
        
        wait( reason: "wait before open diagram", timeout: 3.0 )

        cell.tap()
    
//        XCTAssertTrue( app.tables.element.waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["openai"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["editor"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.buttons["diagram"].waitForExistence(timeout: 10) )

        app.buttons["diagram"].tap()
        app.buttons["openai"].tap()

        XCTAssertTrue( app.buttons["openai_settings"].waitForExistence(timeout: 10) )
        app.buttons["openai_settings"].tap()

        XCTAssertTrue( app.secureTextFields["secure_toggle_field_apikey"].waitForExistence(timeout: 10) )
        XCTAssertTrue( app.secureTextFields["secure_toggle_field_orgid"].exists )
        
        XCTAssertTrue( app.buttons["openai_prompt"].waitForExistence(timeout: 10) )
        app.buttons["openai_prompt"].tap()
        
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
            
//        openaiSubmit( "set title PlantUML meets OpenAI" )
//        openaiSubmit( "make simple sequence diagram" )
//        openaiSubmit( "sequence representing a microservice invoked using an api key" )
        openaiSubmit( "make a simple sequence diagram and then set tile PlantUML meets OpenAI" )
        openaiSubmit( "sequence representing a microservice invoked using an api key" )
        openaiSubmit( "put in evidence participants" )
        openaiSubmit( "add validation api key" )
        openaiSubmit( "grouping api key validation as security" )
//        openaiSubmit( "remove useless (JWT) comment" )

        app.buttons["openai"].tap()

        wait( reason: "wait before exit", timeout: 5.0 )

        app.buttons["editor"].tap()

        XCTAssertTrue( app.buttons["font+"].exists )
        app.buttons["font+"].tap()
        app.buttons["font+"].tap()
        app.buttons["font+"].tap()

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

    func __testPlantUMLKeyboard() throws {

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
