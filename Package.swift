// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PackStream",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "PackStream", targets: ["PackStream"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.50.0"),
    ],
    targets: [
        .target(
            name: "PackStream",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete"),
            ]
        ),
        .testTarget(
            name: "PackStreamTests",
            dependencies: ["PackStream"]
        ),
    ]
)
