// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdventOfCode2023",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMinor(from: "1.0.0")
        ),
        .package(
            url: "https://github.com/LuizZak/swift-z3.git",
            branch: "4.11.2"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "AdventOfCode2023",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftZ3", package: "swift-z3")
            ]
        ),
    ]
)
