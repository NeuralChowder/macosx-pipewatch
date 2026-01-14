// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PipeWatch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PipeWatch",
            targets: ["PipeWatch"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PipeWatch",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PipeWatchTests",
            dependencies: ["PipeWatch"],
            path: "Tests"
        ),
    ]
)
