// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacCalendarSync",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "MacCalendarSyncLib",
            targets: ["MacCalendarSyncLib"]),
        .executable(
            name: "release-tool",
            targets: ["ReleaseTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "MacCalendarSync",
            dependencies: [
                "MacCalendarSyncLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .executableTarget(
            name: "ReleaseTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Subprocess", package: "swift-subprocess"),
            ]),
        .target(
            name: "MacCalendarSyncLib"),
        .testTarget(
            name: "MacCalendarSyncTests",
            dependencies: [
                "MacCalendarSyncLib"
            ]
        ),
    ]
)
