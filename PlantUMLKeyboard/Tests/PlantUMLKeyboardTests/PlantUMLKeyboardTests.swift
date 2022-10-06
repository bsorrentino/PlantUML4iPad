import XCTest
@testable import PlantUMLKeyboard


final class PlantUMLKeyboardTests: XCTestCase {
    
    @Symbol.LineBuilder func makeDeploymentSymbols() -> [[Symbol]] {
       
        Symbol.Line {
           "actor"
           "agent"
           "artifact"
           "boundary"
           "card"
           "circle"
           "cloud"
           "collections"
           "component"
           "control"
           "person"
           ("queue", "queue as q1")
           "rectangle"
       }
       
        Symbol.Line {}

   }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(PlantUMLKeyboardView().text, "Hello, World!")
        
        
        let symbols = makeDeploymentSymbols()
        
        XCTAssertEqual( symbols.count, 2 )
        
        XCTAssertEqual( symbols[0].count, 13 )
        XCTAssertEqual( symbols[1].count, 0 )

        XCTAssertEqual( symbols[0][11].value,  "queue as q1" )

        print( symbols )

    }
}
