import Foundation

/// User settings, stored as individual keys in the App Group defaults so SwiftUI can bind them via `@AppStorage`.
public struct Settings: Sendable, Equatable {
    public enum Key: String, CaseIterable, Sendable {
        case themeID, appearance, thumbnailAppearance, thumbnailTextSize, fontFamily, fontSize, wordWrap, lineNumbers, tabWidth, highlightLimit, showFrontMatter, allowRemoteImages, rawHTML
        /// 0.1.1's on/off predecessor of `thumbnailAppearance`; only read to migrate it.
        case darkThumbnails
    }

    /// Which theme variant previews use.
    public enum Appearance: String, CaseIterable, Sendable {
        /// Follows the system's light or dark appearance.
        case system, light, dark

        /// Value of the CSS `color-scheme` property.
        public var cssColorScheme: String { self == .system ? "light dark" : rawValue }
    }

    /// No system option: Finder doesn't request new thumbnails when the system appearance changes (verified on macOS 26.6).
    public enum ThumbnailAppearance: String, CaseIterable, Sendable {
        case light, dark
    }

    public enum ThumbnailTextSize: String, CaseIterable, Sendable {
        case small, medium, large, veryLarge

        /// On `ThumbnailPage.size`, which Finder scales down to icon size.
        public var points: Double {
            switch self {
            case .small: 20
            case .medium: 26
            case .large: 40
            case .veryLarge: 72
            }
        }
    }

    /// How raw HTML embedded in Markdown is rendered.
    public enum RawHTMLMode: String, CaseIterable, Sendable {
        /// Allowlist of harmless tags and attributes; scripts, styles and remote resources removed.
        case sanitize
        /// Shown as literal text.
        case escape
    }

    public var themeID = Theme.xcode.id
    public var appearance = Appearance.system
    public var thumbnailAppearance = ThumbnailAppearance.light
    public var thumbnailTextSize = ThumbnailTextSize.large
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
        if let v = d.string(forKey: Key.appearance.rawValue).flatMap(Appearance.init) { s.appearance = v }
        if let v = d.string(forKey: Key.thumbnailAppearance.rawValue).flatMap(ThumbnailAppearance.init) {
            s.thumbnailAppearance = v
        } else if d.bool(forKey: Key.darkThumbnails.rawValue) {
            s.thumbnailAppearance = .dark
        }
        if let v = d.string(forKey: Key.thumbnailTextSize.rawValue).flatMap(ThumbnailTextSize.init) { s.thumbnailTextSize = v }
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

    public func save(to defaults: UserDefaults? = AppGroup.defaults) {
        guard let d = defaults else { return }
        d.set(themeID, forKey: Key.themeID.rawValue)
        d.set(appearance.rawValue, forKey: Key.appearance.rawValue)
        d.set(thumbnailAppearance.rawValue, forKey: Key.thumbnailAppearance.rawValue)
        d.removeObject(forKey: Key.darkThumbnails.rawValue)
        d.set(thumbnailTextSize.rawValue, forKey: Key.thumbnailTextSize.rawValue)
        d.set(fontFamily, forKey: Key.fontFamily.rawValue)
        d.set(fontSize, forKey: Key.fontSize.rawValue)
        d.set(wordWrap, forKey: Key.wordWrap.rawValue)
        d.set(lineNumbers, forKey: Key.lineNumbers.rawValue)
        d.set(tabWidth, forKey: Key.tabWidth.rawValue)
        d.set(highlightLimit, forKey: Key.highlightLimit.rawValue)
        d.set(showFrontMatter, forKey: Key.showFrontMatter.rawValue)
        d.set(allowRemoteImages, forKey: Key.allowRemoteImages.rawValue)
        d.set(rawHTML.rawValue, forKey: Key.rawHTML.rawValue)
    }
}
