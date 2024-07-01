import XCTest
@testable import PlantUMLFramework

final class PlantUMLFrameworkTests: XCTestCase {
    
    
    func testPlantUML() {

        let clazz = SyntaxStructure(rawValue: "Bob -> Alice : hello")

        let script = PlantUMLScript( items: [clazz] )

        let url = plantUMLUrl( of: script, format: .ASCIIArt )
        
        print( url )

    }

    func testPlantUMLWithError() {

        let clazz = SyntaxStructure(rawValue: "Bob > Alice : hello")

        let script = PlantUMLScript( items: [clazz] )

        var url = plantUMLUrl( of: script, format: .ASCIIArt )
        
        print( url )

        url = plantUMLUrl( of: script, format: .imagePng )
        
        print( url )

    }
}
