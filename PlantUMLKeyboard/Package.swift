// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlantUMLKeyboard",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PlantUMLKeyboard",
            targets: ["PlantUMLKeyboard"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", branch: "master" ),
        .package(path: "../PlantUMLFramework" ),
        .package(url: "https://github.com/bsorrentino/SwiftUI-LineEditor.git", exact: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PlantUMLKeyboard",
            dependencies: [
                .product(name: "LineEditor", package: "SwiftUI-LineEditor"),
                "PlantUMLFramework"
            ],
            resources: [.copy("plantuml_keyboard_data.json")]
            ),
        .testTarget(
            name: "PlantUMLKeyboardTests",
            dependencies: ["PlantUMLKeyboard", "PlantUMLFramework"]),
    ]
)
