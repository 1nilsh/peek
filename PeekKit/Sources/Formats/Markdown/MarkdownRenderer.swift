import AppKit
import Markdown
import PeekCore
import PeekHighlight

public struct MarkdownRenderer: FormatRenderer {
    /// Markdown renders quickly; only code blocks are highlighted, so the limit is higher than for source code.
    static let sizeLimit = 2_000_000

    public init() {}

    public var displayName: String { "Markdown" }

    public var contentTypes: [String] { ["net.daringfireball.markdown"] }

    public func preview(of file: URL, context: RenderContext) throws -> PreviewDocument {
        let text = try TextFile.read(file, limit: Self.sizeLimit)
        let (frontMatter, markdown) = FrontMatter.split(text.text)

        var body = "<article class=\"markdown\">\n"
        if let frontMatter, context.settings.showFrontMatter {
            body += Self.html(frontMatter)
        }
        var walker = MarkdownHTML(
            baseURL: file.deletingLastPathComponent(),
            allowRemoteImages: context.settings.allowRemoteImages,
            rawHTML: context.settings.rawHTML)
        walker.visit(Document(parsing: String(markdown)))
        body += walker.result
        if let notice = text.truncationNotice {
            body += "<p class=\"peek-notice\">\(notice.htmlEscaped)</p>"
        }
        body += "</article>"

        return PreviewDocument(
            html: HTMLPage.render(body: body, context: context, css: Self.css),
            attachments: walker.attachments)
    }

    public func thumbnail(of file: URL, context: RenderContext) throws -> NSAttributedString {
        let head = ThumbnailPage.head(of: try TextFile.read(file, limit: 8_000).text)
        let result = Highlighter.shared.highlight(head, language: "markdown", autoDetect: false)
        return HighlightedHTML.attributedString(result.html, palette: context.theme.light, font: ThumbnailPage.font)
    }

    static func html(_ frontMatter: FrontMatter) -> String {
        let rows = frontMatter.entries.map { entry in
            let value = entry.value.contains("\n")
                ? "<pre>\(entry.value.htmlEscaped)</pre>"
                : entry.value.htmlEscaped
            return "<tr><th>\(entry.key.htmlEscaped)</th><td>\(value)</td></tr>"
        }
        return "<table class=\"front-matter\">\n\(rows.joined(separator: "\n"))\n</table>\n"
    }

    static let css = """
        :root { --border: color-mix(in srgb, var(--fg) 16%, var(--bg)); --code-bg: color-mix(in srgb, var(--fg) 6%, var(--bg)); }
        .markdown { max-width: 860px; margin: 0 auto; font-size: 15px; line-height: 1.6; overflow-wrap: break-word; }
        .markdown > :first-child { margin-top: 0; }
        h1, h2, h3, h4, h5, h6 { margin: 1.4em 0 0.6em; line-height: 1.25; font-weight: 600; }
        h1 { font-size: 2em; } h2 { font-size: 1.5em; } h3 { font-size: 1.25em; } h4 { font-size: 1em; }
        h5 { font-size: 0.875em; } h6 { font-size: 0.85em; color: var(--secondary); }
        h1, h2 { padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
        p, ul, ol, blockquote, table, pre { margin: 0 0 1em; }
        a { color: var(--link); text-decoration: none; } a:hover { text-decoration: underline; }
        code { font-size: 85%; padding: 0.15em 0.35em; border-radius: 5px; background: var(--code-bg); }
        pre.code { padding: 12px 16px; border-radius: 6px; background: var(--code-bg); overflow: auto; }
        pre.code code { font-size: var(--code-size); padding: 0; background: none; }
        blockquote { margin-left: 0; padding: 0 1em; color: var(--secondary); border-left: 0.25em solid var(--border); }
        hr { height: 0.25em; border: 0; background: var(--border); margin: 1.5em 0; }
        table { border-collapse: collapse; display: block; max-width: 100%; overflow: auto; }
        th, td { padding: 6px 13px; border: 1px solid var(--border); }
        th { font-weight: 600; }
        tr:nth-child(2n) td { background: var(--code-bg); }
        li.task { list-style: none; } li.task input { margin: 0 0.3em 0 -1.4em; vertical-align: middle; }
        img { max-width: 100%; }
        .peek-missing-image { color: var(--secondary); border: 1px dashed var(--border); border-radius: 4px; padding: 0 0.4em; }
        .front-matter { font-size: 0.85em; margin-bottom: 1.5em; }
        .front-matter th { text-align: left; color: var(--secondary); font-weight: 500; vertical-align: top; }
        .front-matter td, .front-matter th { background: none !important; }
        .front-matter pre, pre.raw-html { margin: 0; font-family: var(--mono); white-space: pre-wrap; }
        pre.raw-html { margin-bottom: 1em; color: var(--secondary); font-size: var(--code-size); }
        """
}
