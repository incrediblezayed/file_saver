// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "file_saver",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "file-saver", targets: ["file_saver"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "file_saver",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
