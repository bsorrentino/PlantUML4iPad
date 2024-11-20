// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AIAgent",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AIAgent",
            targets: ["AIAgent"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/bsorrentino/LangGraph-Swift.git", exact: "2.0.0"),
        .package(url: "https://github.com/bsorrentino/LangGraph-Swift.git", branch: "main"),
//        .package(url: "https://github.com/bsorrentino/Swift-OpenAI.git", branch: "develop"), // Add the dependency here
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AIAgent", 
            dependencies: [
//                .product(name: "OpenAI", package: "Swift-OpenAI"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "LangGraph", package: "LangGraph-Swift")
            ], resources: [ .process("Resources")]),
        .testTarget(
            name: "AIAgentTests",
            dependencies: ["AIAgent"]),
    ]
)
