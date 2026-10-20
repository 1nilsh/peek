// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekKit",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "PeekCore", targets: ["PeekCore"]),
        .library(name: "PeekFormats", targets: ["PeekFormats"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0"),
    ],
    targets: [
        .target(name: "PeekCore"),
        .target(
            name: "PeekHighlight",
            dependencies: ["PeekCore"],
            resources: [.copy("Resources/highlight.min.js"), .copy("Resources/languages")]
        ),
        .target(name: "PeekSourceCode", dependencies: ["PeekCore", "PeekHighlight"], path: "Sources/Formats/SourceCode"),
        .target(
            name: "PeekMarkdown",
            dependencies: ["PeekCore", "PeekHighlight", .product(name: "Markdown", package: "swift-markdown")],
            path: "Sources/Formats/Markdown"
        ),
        .target(name: "PeekFormats", dependencies: ["PeekCore", "PeekSourceCode", "PeekMarkdown"]),
        .testTarget(name: "PeekCoreTests", dependencies: ["PeekCore"]),
        .testTarget(name: "PeekHighlightTests", dependencies: ["PeekHighlight"]),
        .testTarget(name: "PeekFormatsTests", dependencies: ["PeekFormats", "PeekSourceCode", "PeekMarkdown"]),
    ]
)
