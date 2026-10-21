import AppKit
import UniformTypeIdentifiers

/// A file format Peek can preview and thumbnail. Register new formats in `FormatRegistry`.
public protocol FormatRenderer: Sendable {
    /// Shown in the host app, e.g. "Markdown".
    var displayName: String { get }

    /// UTI identifiers handled by this renderer. Strings rather than `UTType`s, because
    /// imported types are unknown outside the app bundle. Must match `QLSupportedContentTypes` in project.yml.
    var contentTypes: [String] { get }

    func preview(of file: URL, context: RenderContext) throws -> PreviewDocument

    /// Text drawn onto the thumbnail page; only the part that fits on `ThumbnailPage.size` is visible.
    func thumbnail(of file: URL, context: RenderContext) throws -> NSAttributedString
}

public struct RenderContext: Sendable {
    public var settings: Settings
    public var contentType: UTType?

    public init(settings: Settings, contentType: UTType?) {
        self.settings = settings
        self.contentType = contentType
    }

    public var theme: Theme { Theme.named(settings.themeID) }

    public var thumbnailPalette: Palette { settings.darkThumbnails ? theme.dark : theme.light }

    public var thumbnailFont: NSFont { .monospacedSystemFont(ofSize: settings.thumbnailTextSize.points, weight: .regular) }
}

public struct PreviewDocument: Sendable {
    public var html: String
    /// Keyed by content ID; reference as `cid:<key>` in `html`.
    public var attachments: [String: Attachment]
    public var size: CGSize

    public init(html: String, attachments: [String: Attachment] = [:], size: CGSize = CGSize(width: 900, height: 1000)) {
        self.html = html
        self.attachments = attachments
        self.size = size
    }
}

public struct Attachment: Sendable {
    public var data: Data
    public var contentType: UTType

    public init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }
}
