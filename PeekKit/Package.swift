// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekKit",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "PeekCore", targets: ["PeekCore"]),
        .library(name: "PeekHighlight", targets: ["PeekHighlight"]),
    ],
    targets: [
        .target(name: "PeekCore"),
        .target(
            name: "PeekHighlight",
            dependencies: ["PeekCore"],
            resources: [.copy("Resources/highlight.min.js")]
        ),
        .testTarget(name: "PeekHighlightTests", dependencies: ["PeekHighlight"]),
    ]
)
