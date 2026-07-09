// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacMenuBarCommandKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MacMenuBarCommandKit", targets: ["MacMenuBarCommandKit"])
    ],
    targets: [
        .target(name: "MacMenuBarCommandKit"),
        .testTarget(
            name: "MacMenuBarCommandKitTests",
            dependencies: ["MacMenuBarCommandKit"]
        )
    ]
)
