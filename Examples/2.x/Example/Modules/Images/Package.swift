// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Images",
    platforms: [.iOS("13.0")],
    products: [
        .library(
            name: "Images",
            targets: ["Images"]
        ),
    ],
    dependencies: [
        .package(path: "../../../../..")
    ],
    targets: [
        .target(
            name: "Images",
            dependencies: [
            ],
            plugins: [
                //.plugin(name: "ImagelinterPlugin", package: "Imagelinter"),
            ]
        )
    ]
)
