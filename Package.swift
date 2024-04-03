// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Imagelinter",
    platforms: [.iOS(.v12), .macOS(.v11)],
    products: [
        .library(
            name: "Imagelinter",
            targets: ["Imagelinter"]
        ),
        .plugin(
            name: "ImagelinterPlugin",
            targets: ["ImagelinterPlugin"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Imagelinter",
            dependencies: []
        ),
        .executableTarget(
            name: "ImagelinterExec",
            dependencies: [ ]
        ),
        .plugin(name: "ImagelinterPlugin", capability: .buildTool(), dependencies: ["ImagelinterExec"])
    ]
)
