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

//        print( symbols )

    }

    
    func testRef() throws {
    
        do {
            
            let ref_1 = try Symbol.matchRef( in: "test" )
            XCTAssertNil(ref_1)

            let ref_2 = try Symbol.matchRef( in: "#ref(note left)" )
            XCTAssertNotNil(ref_2)
            XCTAssertEqual(  ref_2 , "note left" )
            
            let ref_3 = try Symbol.matchRef( in: "#ref(   note left)" )
            XCTAssertNotNil(ref_3)
            XCTAssertEqual(  ref_3 , "note left" )

            let ref_4 = try Symbol.matchRef( in: "#ref(note left    )" )
            XCTAssertNotNil(ref_4)
            XCTAssertEqual(  ref_4 , "note left" )

            let ref_5 = try Symbol.matchRef( in: "#ref(  note left    )" )
            XCTAssertNotNil(ref_5)
            XCTAssertEqual(  ref_5 , "note left" )

            let ref_6 = try Symbol.matchRef( in: "#ref(  mixed by erry    )" )
            XCTAssertNotNil(ref_6)
            XCTAssertEqual(  ref_6 , "mixed by erry" )

        } catch {
            XCTFail( "error evaluating isReference regular expression: \(error)")
        }
 

//        print( symbols )

    }
}
