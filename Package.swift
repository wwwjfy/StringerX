// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StringerX",
    platforms: [
        .macOS(.v15)  // macOS 15 (will update build settings to target macOS 26 when that exists)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "StringerX",
            dependencies: ["SwiftSoup"],
            path: "StringerX"
        )
    ]
)
