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
            targets: ["MacCalendarSyncLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "MacCalendarSync",
            dependencies: [
                "MacCalendarSyncLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
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
