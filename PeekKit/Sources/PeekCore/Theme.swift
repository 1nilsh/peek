import AppKit

/// Semantic token categories that highlight.js scopes are mapped onto.
public enum TokenRole: String, CaseIterable, Sendable {
    case keyword, builtIn, type, string, number, comment, title, attribute, variable, meta, tag, section, link, addition, deletion
}

public struct RGB: Sendable, Hashable {
    public let value: UInt32
    public init(_ value: UInt32) { self.value = value }

    public var css: String { String(format: "#%06x", value) }
    public var nsColor: NSColor {
        NSColor(srgbRed: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255,
                blue: CGFloat(value & 0xff) / 255, alpha: 1)
    }
}

public struct Palette: Sendable {
    public var background: RGB
    public var foreground: RGB
    /// Line numbers, table borders, front matter keys.
    public var secondary: RGB
    public var tokens: [TokenRole: RGB]
}

/// One source of truth for colors in both the HTML preview (CSS) and thumbnails (`NSAttributedString`).
public struct Theme: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let light: Palette
    public let dark: Palette

    public static let all: [Theme] = [xcode, github]

    public static func named(_ id: String) -> Theme { all.first { $0.id == id } ?? xcode }

    public static let xcode = Theme(
        id: "xcode", name: "Xcode",
        light: Palette(background: RGB(0xffffff), foreground: RGB(0x1f1f24), secondary: RGB(0x8a8a8e), tokens: [
            .keyword: RGB(0xad3da4), .builtIn: RGB(0x804fb8), .type: RGB(0x703daa), .string: RGB(0xd12f1b),
            .number: RGB(0x272ad8), .comment: RGB(0x707f8c), .title: RGB(0x0f68a0), .attribute: RGB(0x947100),
            .variable: RGB(0x3e8087), .meta: RGB(0x78492a), .tag: RGB(0x0f68a0), .section: RGB(0x0f68a0),
            .link: RGB(0x0e0eff), .addition: RGB(0x1a7f37), .deletion: RGB(0xb31d28),
        ]),
        dark: Palette(background: RGB(0x1f1f24), foreground: RGB(0xdfdfe0), secondary: RGB(0x7f8c98), tokens: [
            .keyword: RGB(0xff7ab2), .builtIn: RGB(0xb281eb), .type: RGB(0xdabaff), .string: RGB(0xff8170),
            .number: RGB(0xd9c97c), .comment: RGB(0x7f8c98), .title: RGB(0x4eb0cc), .attribute: RGB(0xcc9768),
            .variable: RGB(0x78c2b3), .meta: RGB(0xfd8f3f), .tag: RGB(0x4eb0cc), .section: RGB(0x6bdfff),
            .link: RGB(0x6699ff), .addition: RGB(0x67b7a4), .deletion: RGB(0xff7b72),
        ])
    )

    public static let github = Theme(
        id: "github", name: "GitHub",
        light: Palette(background: RGB(0xffffff), foreground: RGB(0x1f2328), secondary: RGB(0x6e7781), tokens: [
            .keyword: RGB(0xcf222e), .builtIn: RGB(0x953800), .type: RGB(0x953800), .string: RGB(0x0a3069),
            .number: RGB(0x0550ae), .comment: RGB(0x6e7781), .title: RGB(0x8250df), .attribute: RGB(0x0550ae),
            .variable: RGB(0x953800), .meta: RGB(0x0550ae), .tag: RGB(0x116329), .section: RGB(0x0550ae),
            .link: RGB(0x0a3069), .addition: RGB(0x116329), .deletion: RGB(0x82071e),
        ]),
        dark: Palette(background: RGB(0x0d1117), foreground: RGB(0xe6edf3), secondary: RGB(0x8b949e), tokens: [
            .keyword: RGB(0xff7b72), .builtIn: RGB(0xffa657), .type: RGB(0xffa657), .string: RGB(0xa5d6ff),
            .number: RGB(0x79c0ff), .comment: RGB(0x8b949e), .title: RGB(0xd2a8ff), .attribute: RGB(0x79c0ff),
            .variable: RGB(0xffa657), .meta: RGB(0x79c0ff), .tag: RGB(0x7ee787), .section: RGB(0x1f6feb),
            .link: RGB(0xa5d6ff), .addition: RGB(0x7ee787), .deletion: RGB(0xffa198),
        ])
    )

    /// CSS custom properties `--bg`, `--fg`, `--secondary`, `--<role>`; for `.system` both variants via media query.
    public func cssVariables(for appearance: Settings.Appearance) -> String {
        func vars(_ p: Palette) -> String {
            (["--bg: \(p.background.css)", "--fg: \(p.foreground.css)", "--secondary: \(p.secondary.css)"]
                + TokenRole.allCases.compactMap { r in p.tokens[r].map { "--\(r.rawValue): \($0.css)" } })
                .joined(separator: "; ")
        }
        switch appearance {
        case .system: return ":root { \(vars(light)); }\n@media (prefers-color-scheme: dark) { :root { \(vars(dark)); } }"
        case .light: return ":root { \(vars(light)); }"
        case .dark: return ":root { \(vars(dark)); }"
        }
    }
}
