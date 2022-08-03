import UIKit

var greeting = "Hello, playground"

let clazz = SyntaxStructure( rawValue: "class Test" )

let script = PlantUMLScript( items: [clazz] )

script.text

let presenter = PlantUMLBrowserPresenter( format: .imagePng)

presenter.url( of: script )
