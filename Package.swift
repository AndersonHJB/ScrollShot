// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScrollShot",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScrollShot", targets: ["ScrollShotApp"]),
        .library(name: "ScrollShotCore", targets: ["ScrollShotCore"])
    ],
    targets: [
        .target(
            name: "ScrollShotCore",
            path: "Sources/ScrollShotCore"
        ),
        .executableTarget(
            name: "ScrollShotApp",
            dependencies: ["ScrollShotCore"],
            path: "Sources/ScrollShotApp"
        ),
        .testTarget(
            name: "ScrollShotCoreTests",
            dependencies: ["ScrollShotCore"],
            path: "Tests/ScrollShotCoreTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
