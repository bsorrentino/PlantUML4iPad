import UIKit

var greeting = "Hello, playground"

let clazz = SyntaxStructure(
    accessibility: ElementAccessibility.public,
    attribute: "attribute",
    attributes: nil,
    elements: nil,
    inheritedTypes: nil,
    kind: ElementKind.class,
    name: "Test",
    runtimename: "runtimename",
    substructure: nil,
    typename: "typename"
)

let script = PlantUMLScript( items: [clazz] )

script.text

let presenter = PlantUMLBrowserPresenter( format: .imagePng)

presenter.url( of: script )
