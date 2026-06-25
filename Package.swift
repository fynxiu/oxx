// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "oxx",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "oxx", targets: ["oxx"]),
        .executable(name: "oxx-service", targets: ["oxx-service"]),
        .library(name: "OxxCore", targets: ["OxxCore"])
    ],
    targets: [
        .target(name: "OxxCore"),
        .executableTarget(
            name: "oxx",
            dependencies: ["OxxCore"]
        ),
        .executableTarget(
            name: "oxx-service",
            dependencies: ["OxxCore"]
        ),
        .testTarget(
            name: "OxxCoreTests",
            dependencies: ["OxxCore"]
        )
    ]
)
