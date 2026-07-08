// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iCloudScreenshotSweeper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "screenshot-sweeper", targets: ["ScreenshotSweeper"])
    ],
    targets: [
        .target(
            name: "ScreenshotSweeperCore",
            linkerSettings: [
                .linkedFramework("Photos")
            ]
        ),
        .executableTarget(
            name: "ScreenshotSweeper",
            dependencies: ["ScreenshotSweeperCore"]
        ),
        .testTarget(
            name: "ScreenshotSweeperTests",
            dependencies: ["ScreenshotSweeperCore"]
        )
    ]
)
