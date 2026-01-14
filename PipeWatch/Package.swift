// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PipeWatch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Pipe Watch",
            targets: ["PipeWatch"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .executableTarget(
            name: "PipeWatch",
            dependencies: ["KeychainAccess"],
            path: "Sources",
            exclude: ["Resources/Info.plist", "Resources/PipeWatch.entitlements", "Resources/AppIcon.icns"]
        )
    ]
)
