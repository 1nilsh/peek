import Foundation

/// User settings, stored as individual keys in the App Group defaults so SwiftUI can bind them via `@AppStorage`.
public struct Settings: Sendable, Equatable {
    public enum Key: String, CaseIterable, Sendable {
        case themeID, fontFamily, fontSize, wordWrap, lineNumbers, tabWidth, highlightLimit, showFrontMatter, allowRemoteImages, rawHTML
    }

    /// How raw HTML embedded in Markdown is rendered.
    public enum RawHTMLMode: String, CaseIterable, Sendable {
        /// Allowlist of harmless tags and attributes; scripts, styles and remote resources removed.
        case sanitize
        /// Shown as literal text.
        case escape
    }

    public var themeID = Theme.xcode.id
    /// Empty means the system monospaced font.
    public var fontFamily = ""
    public var fontSize = 12.0
    public var wordWrap = true
    public var lineNumbers = false
    public var tabWidth = 4
    /// Bytes highlighted before the preview is truncated.
    public var highlightLimit = 200_000
    public var showFrontMatter = true
    public var allowRemoteImages = false
    public var rawHTML = RawHTMLMode.sanitize

    public init() {}

    public static func load(from defaults: UserDefaults? = AppGroup.defaults) -> Settings {
        var s = Settings()
        guard let d = defaults else { return s }
        if let v = d.string(forKey: Key.themeID.rawValue) { s.themeID = v }
        if let v = d.string(forKey: Key.fontFamily.rawValue) { s.fontFamily = v }
        if d.object(forKey: Key.fontSize.rawValue) != nil { s.fontSize = d.double(forKey: Key.fontSize.rawValue) }
        if d.object(forKey: Key.wordWrap.rawValue) != nil { s.wordWrap = d.bool(forKey: Key.wordWrap.rawValue) }
        if d.object(forKey: Key.lineNumbers.rawValue) != nil { s.lineNumbers = d.bool(forKey: Key.lineNumbers.rawValue) }
        if d.object(forKey: Key.tabWidth.rawValue) != nil { s.tabWidth = d.integer(forKey: Key.tabWidth.rawValue) }
        if d.object(forKey: Key.highlightLimit.rawValue) != nil { s.highlightLimit = d.integer(forKey: Key.highlightLimit.rawValue) }
        if d.object(forKey: Key.showFrontMatter.rawValue) != nil { s.showFrontMatter = d.bool(forKey: Key.showFrontMatter.rawValue) }
        if d.object(forKey: Key.allowRemoteImages.rawValue) != nil { s.allowRemoteImages = d.bool(forKey: Key.allowRemoteImages.rawValue) }
        if let v = d.string(forKey: Key.rawHTML.rawValue).flatMap(RawHTMLMode.init) { s.rawHTML = v }
        return s
    }
}
