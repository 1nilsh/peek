/// A highlighted `<pre>` block, optionally with CSS line numbers (not part of the selectable text).
public enum CodeBlock {
    public static func html(_ result: HighlightResult, lineNumbers: Bool) -> String {
        let lang = result.language.map { " data-language=\"\($0.htmlEscaped)\"" } ?? ""
        guard lineNumbers else { return "<pre class=\"code\"\(lang)><code>\(result.html)</code></pre>" }
        let lines = HighlightedHTML.lines(result.html)
        let digits = String(lines.count).count
        let body = lines.map { "<span class=\"line\">\($0)</span>" }.joined(separator: "\n")
        return "<pre class=\"code numbered\" style=\"--digits: \(digits)\"\(lang)><code>\(body)</code></pre>"
    }

    public static let css = """
        .numbered { counter-reset: line; }
        .numbered .line { display: block; padding-left: calc(var(--digits) * 1ch + 1.5em); text-indent: calc(-1 * (var(--digits) * 1ch + 1.5em)); }
        .numbered .line::before {
          counter-increment: line; content: counter(line);
          display: inline-block; width: calc(var(--digits) * 1ch); margin-right: 1.5em; text-indent: 0;
          text-align: right; color: var(--secondary); -webkit-user-select: none; user-select: none;
        }
        """
}
