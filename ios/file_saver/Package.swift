// swift-tools-version: 5.9

import Foundation
import PackageDescription

/// Whether to build `saveToGallery` and link Photos. Checked in order:
/// 1. `FILE_SAVER_PHOTOS` is set: "0" means off, anything else means on.
/// 2. The app's ios/Runner/Info.plist has a photo library usage key: on.
///    It has neither key: off.
/// 3. Info.plist can't be found or read: on.
/// See "Gallery support on iOS" in the README.
func isGalleryEnabled() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    if let value = environment["FILE_SAVER_PHOTOS"], !value.isEmpty {
        return value != "0"
    }
    guard let plist = findRunnerInfoPlist(environment),
        let keys = try? NSDictionary(contentsOf: plist, error: ())
    else {
        FileHandle.standardError.write(
            Data("file_saver: ios/Runner/Info.plist not found or unreadable, so gallery support stays on. Set FILE_SAVER_PHOTOS=0 to turn it off.\n".utf8)
        )
        return true
    }
    return keys["NSPhotoLibraryUsageDescription"] != nil
        || keys["NSPhotoLibraryAddUsageDescription"] != nil
}

/// Walks up to the app's ios/Runner/Info.plist. The package path is tried last:
/// pub.dev packages live in the pub cache, outside the app.
func findRunnerInfoPlist(_ environment: [String: String]) -> URL? {
    let fileManager = FileManager.default
    for case let start? in [fileManager.currentDirectoryPath, environment["PWD"], #filePath] {
        let directories = sequence(first: URL(fileURLWithPath: start)) { $0.deletingLastPathComponent() }
        for directory in directories.prefix(12) {
            let plist = directory.appendingPathComponent("ios/Runner/Info.plist")
            if fileManager.fileExists(atPath: plist.path),
                fileManager.fileExists(atPath: directory.appendingPathComponent("pubspec.yaml").path)
            {
                return plist
            }
        }
    }
    return nil
}

let galleryEnabled = isGalleryEnabled()

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
            ],
            swiftSettings: galleryEnabled ? [.define("FILE_SAVER_PHOTOS")] : [],
            linkerSettings: galleryEnabled ? [.linkedFramework("Photos")] : []
        )
    ]
)
