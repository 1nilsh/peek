// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekKit",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "PeekCore", targets: ["PeekCore"]),
        .library(name: "PeekFormats", targets: ["PeekFormats"]),
    ],
    targets: [
        .target(name: "PeekCore"),
        .target(
            name: "PeekHighlight",
            dependencies: ["PeekCore"],
            resources: [.copy("Resources/highlight.min.js"), .copy("Resources/languages")]
        ),
        .target(name: "PeekSourceCode", dependencies: ["PeekCore", "PeekHighlight"], path: "Sources/Formats/SourceCode"),
        .target(name: "PeekFormats", dependencies: ["PeekCore", "PeekSourceCode"]),
        .testTarget(name: "PeekCoreTests", dependencies: ["PeekCore"]),
        .testTarget(name: "PeekHighlightTests", dependencies: ["PeekHighlight"]),
        .testTarget(name: "PeekFormatsTests", dependencies: ["PeekFormats", "PeekSourceCode"]),
    ]
)
