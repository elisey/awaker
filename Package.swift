// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "awaker",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "awaker",
            path: "Sources/awaker",
            // Everything runs on the main thread via AppKit; the strict-concurrency checker
            // of mode 6 cannot see that for NSObject subclasses and only adds noise.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "awakerTests",
            dependencies: ["awaker"],
            path: "Tests/awakerTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
