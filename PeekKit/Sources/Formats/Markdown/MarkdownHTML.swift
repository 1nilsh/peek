import Foundation
import Markdown
import PeekCore
import PeekHighlight
import UniformTypeIdentifiers

/// Renders a swift-markdown tree to HTML. Unlike swift-markdown's `HTMLFormatter`, it escapes attributes,
/// emits image alt text, highlights code blocks, autolinks bare URLs, embeds local images as attachments,
/// and never passes raw HTML or unsafe link schemes through unfiltered.
struct MarkdownHTML: MarkupWalker {
    static let maxImageBytes = 20_000_000

    private(set) var result = ""
    private(set) var attachments: [String: Attachment] = [:]

    private let baseURL: URL
    private let allowRemoteImages: Bool
    private let rawHTML: Settings.RawHTMLMode
    private var imageIDs: [URL: String] = [:]
    private var imageBytes = 0
    private var linkDepth = 0
    private var inTableHead = false
    private var columnAlignments: [Table.ColumnAlignment?] = []
    private var column = 0

    /// - Parameter baseURL: Directory that relative image paths resolve against.
    init(baseURL: URL, allowRemoteImages: Bool, rawHTML: Settings.RawHTMLMode = .sanitize) {
        // Without a trailing slash, relative resolution would replace the last path component.
        self.baseURL = URL(filePath: baseURL.path(percentEncoded: false), directoryHint: .isDirectory)
        self.allowRemoteImages = allowRemoteImages
        self.rawHTML = rawHTML
    }

    // MARK: Blocks

    mutating func visitParagraph(_ paragraph: Paragraph) { wrap("p", paragraph, newline: true) }

    mutating func visitHeading(_ heading: Heading) { wrap("h\(heading.level)", heading, newline: true) }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) { result += "<hr>\n" }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        switch rawHTML {
        case .sanitize: result += HTMLSanitizer.sanitize(html.rawHTML) { imageSource($0) }
        case .escape: result += "<pre class=\"raw-html\">\(html.rawHTML.htmlEscaped)</pre>\n"
        }
    }

    mutating func visitCodeBlock(_ codeBlock: Markdown.CodeBlock) {
        let language = codeBlock.language?.split(separator: " ").first.map(String.init)
        let highlighted = Highlighter.shared.highlight(codeBlock.code, language: language, autoDetect: false)
        result += PeekHighlight.CodeBlock.html(highlighted, lineNumbers: false) + "\n"
    }

    mutating func visitOrderedList(_ list: OrderedList) {
        result += list.startIndex == 1 ? "<ol>\n" : "<ol start=\"\(list.startIndex)\">\n"
        descendInto(list)
        result += "</ol>\n"
    }

    mutating func visitUnorderedList(_ list: UnorderedList) {
        result += "<ul>\n"
        descendInto(list)
        result += "</ul>\n"
    }

    mutating func visitListItem(_ item: ListItem) {
        if let checkbox = item.checkbox {
            result += "<li class=\"task\"><input type=\"checkbox\" disabled\(checkbox == .checked ? " checked" : "")> "
        } else {
            result += "<li>"
        }
        descendInto(item)
        result += "</li>\n"
    }

    mutating func visitTable(_ table: Table) {
        columnAlignments = table.columnAlignments
        result += "<table>\n"
        descendInto(table)
        result += "</table>\n"
    }

    mutating func visitTableHead(_ head: Table.Head) {
        inTableHead = true
        column = 0
        result += "<thead><tr>\n"
        descendInto(head)
        result += "</tr></thead>\n"
        inTableHead = false
    }

    mutating func visitTableBody(_ body: Table.Body) {
        guard !body.isEmpty else { return }
        result += "<tbody>\n"
        descendInto(body)
        result += "</tbody>\n"
    }

    mutating func visitTableRow(_ row: Table.Row) {
        column = 0
        result += "<tr>\n"
        descendInto(row)
        result += "</tr>\n"
    }

    mutating func visitTableCell(_ cell: Table.Cell) {
        guard cell.colspan > 0, cell.rowspan > 0 else { return }
        let tag = inTableHead ? "th" : "td"
        var attrs = ""
        if column < columnAlignments.count, let alignment = columnAlignments[column] {
            attrs += " style=\"text-align: \(alignment)\""
        }
        if cell.colspan > 1 { attrs += " colspan=\"\(cell.colspan)\"" }
        if cell.rowspan > 1 { attrs += " rowspan=\"\(cell.rowspan)\"" }
        column += Int(cell.colspan)
        result += "<\(tag)\(attrs)>"
        descendInto(cell)
        result += "</\(tag)>\n"
    }

    // MARK: Inlines

    mutating func visitText(_ text: Markdown.Text) {
        result += linkDepth > 0 ? text.string.htmlEscaped : Self.autolinked(text.string)
    }

    mutating func visitInlineCode(_ code: InlineCode) { result += "<code>\(code.code.htmlEscaped)</code>" }
    mutating func visitEmphasis(_ emphasis: Emphasis) { wrap("em", emphasis) }
    mutating func visitStrong(_ strong: Strong) { wrap("strong", strong) }
    mutating func visitStrikethrough(_ strikethrough: Strikethrough) { wrap("del", strikethrough) }
    mutating func visitInlineHTML(_ html: InlineHTML) {
        switch rawHTML {
        case .sanitize: result += HTMLSanitizer.sanitize(html.rawHTML) { imageSource($0) }
        case .escape: result += html.rawHTML.htmlEscaped
        }
    }
    mutating func visitLineBreak(_ lineBreak: LineBreak) { result += "<br>\n" }
    mutating func visitSoftBreak(_ softBreak: SoftBreak) { result += "\n" }
    mutating func visitSymbolLink(_ link: SymbolLink) { result += "<code>\((link.destination ?? "").htmlEscaped)</code>" }

    mutating func visitLink(_ link: Link) {
        let destination = link.destination.flatMap { URLPolicy.isSafeLink($0) ? $0 : nil }
        let href = destination.map { " href=\"\($0.htmlEscaped)\"" } ?? ""
        result += "<a\(href)\(link.title.map { " title=\"\($0.htmlEscaped)\"" } ?? "")>"
        linkDepth += 1
        descendInto(link)
        linkDepth -= 1
        result += "</a>"
    }

    mutating func visitImage(_ image: Image) {
        let alt = image.plainText.htmlEscaped
        let title = image.title.map { " title=\"\($0.htmlEscaped)\"" } ?? ""
        guard let source = image.source, !source.isEmpty, let src = imageSource(source) else {
            result += "<span class=\"peek-missing-image\" title=\"\((image.source ?? "").htmlEscaped)\">\(alt.isEmpty ? "image" : alt)</span>"
            return
        }
        result += "<img src=\"\(src.htmlEscaped)\" alt=\"\(alt)\"\(title)>"
    }

    // MARK: Helpers

    private mutating func wrap(_ tag: String, _ markup: Markup, newline: Bool = false) {
        result += "<\(tag)>"
        descendInto(markup)
        result += "</\(tag)>" + (newline ? "\n" : "")
    }

    /// `src` for an image reference: remote URLs only if allowed, local files as `cid:` attachments.
    private mutating func imageSource(_ source: String) -> String? {
        let url = URL(string: source, relativeTo: baseURL) ?? baseURL.appending(path: source)
        switch url.scheme?.lowercased() {
        case "data": return source
        case "http", "https": return allowRemoteImages ? source : nil
        case "file": break
        default: return nil
        }
        let file = url.standardizedFileURL
        if let id = imageIDs[file] { return "cid:\(id)" }
        guard
            let type = UTType(filenameExtension: file.pathExtension), type.conforms(to: .image),
            let data = try? Data(contentsOf: file, options: .mappedIfSafe),
            imageBytes + data.count <= Self.maxImageBytes
        else { return nil }
        let id = "img\(imageIDs.count)"
        imageIDs[file] = id
        imageBytes += data.count
        attachments[id] = Attachment(data: data, contentType: type)
        return "cid:\(id)"
    }

    nonisolated(unsafe) private static let urlPattern = /https?:\/\/[^\s<>"]+/

    /// Escapes `text`, wrapping bare http(s) URLs in links (swift-markdown has no GFM autolink extension).
    static func autolinked(_ text: String) -> String {
        var out = ""
        var rest = text[...]
        while let match = rest.firstMatch(of: urlPattern) {
            var url = match.output[...]
            while let last = url.last, ".,:;!?'\")]".contains(last) { url = url.dropLast() }
            out += rest[..<match.range.lowerBound].htmlEscaped
            out += "<a href=\"\(url.htmlEscaped)\">\(url.htmlEscaped)</a>"
            rest = rest[url.endIndex...]
        }
        return out + rest.htmlEscaped
    }
}

private extension Substring {
    var htmlEscaped: String { String(self).htmlEscaped }
}
