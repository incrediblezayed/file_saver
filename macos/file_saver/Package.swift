// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "file_saver",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "file-saver", targets: ["file_saver"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "file_saver",
            dependencies: []
        )
    ]
)
