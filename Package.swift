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
            dependencies: ["ScreenshotSweeperCore"],
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT",
                              "-Xlinker", "__info_plist", "-Xlinker",
                              "Sources/ScreenshotSweeper/Info.plist"])
            ]
        ),
        .testTarget(
            name: "ScreenshotSweeperTests",
            dependencies: ["ScreenshotSweeperCore"]
        )
    ]
)
