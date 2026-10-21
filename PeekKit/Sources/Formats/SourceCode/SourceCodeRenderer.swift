import AppKit
import PeekCore
import PeekHighlight

public struct SourceCodeRenderer: FormatRenderer {
    public init() {}

    public var displayName: String { "Source Code" }

    public var contentTypes: [String] { LanguageMap.contentTypes }

    public func preview(of file: URL, context: RenderContext) throws -> PreviewDocument {
        let text = try TextFile.read(file, limit: context.settings.highlightLimit)
        let language = LanguageMap.language(for: context.contentType, fileExtension: file.pathExtension)
        let result = Highlighter.shared.highlight(text.text, language: language)
        var body = CodeBlock.html(result, lineNumbers: context.settings.lineNumbers)
        if let notice = text.truncationNotice {
            body += "<p class=\"peek-notice\">\(notice.htmlEscaped)</p>"
        }
        return PreviewDocument(html: HTMLPage.render(body: body, context: context, css: CodeBlock.css))
    }

    public func thumbnail(of file: URL, context: RenderContext) throws -> NSAttributedString {
        let head = ThumbnailPage.head(of: try TextFile.read(file, limit: 8_000).text)
        let language = LanguageMap.language(for: context.contentType, fileExtension: file.pathExtension)
        let result = Highlighter.shared.highlight(head, language: language)
        return HighlightedHTML.attributedString(result.html, palette: context.thumbnailPalette, font: context.thumbnailFont)
    }
}
