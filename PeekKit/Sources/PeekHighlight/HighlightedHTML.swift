import AppKit
import PeekCore

/// Operations on highlight.js output, which only contains `<span class="…">`, `</span>`, text and the
/// entities `&amp; &lt; &gt; &quot; &#x27;`.
public enum HighlightedHTML {
    /// Splits into one fragment per source line, closing and reopening spans that cross line breaks.
    public static func lines(_ html: String) -> [String] {
        var lines: [String] = []
        var current = ""
        var open: [Substring] = []
        var rest = html[...]
        while let i = rest.firstIndex(where: { $0 == "<" || $0 == "\n" }) {
            current += rest[..<i]
            if rest[i] == "\n" {
                lines.append(current + String(repeating: "</span>", count: open.count))
                current = open.joined()
                rest = rest[rest.index(after: i)...]
            } else if rest[i...].hasPrefix("</span>") {
                open.removeLast()
                current += "</span>"
                rest = rest[rest.index(i, offsetBy: 7)...]
            } else {
                let end = rest[i...].firstIndex(of: ">") ?? rest.index(before: rest.endIndex)
                let tag = rest[i...end]
                open.append(tag)
                current += tag
                rest = rest[rest.index(after: end)...]
            }
        }
        lines.append(current + rest)
        return lines
    }

    public static func attributedString(_ html: String, palette: Palette, font: NSFont) -> NSAttributedString {
        let out = NSMutableAttributedString()
        var styles: [(TokenRole?, HighlightScopes.Trait?)] = []
        var rest = html[...]

        func append(_ text: some StringProtocol) {
            guard !text.isEmpty else { return }
            let role = styles.lazy.reversed().compactMap(\.0).first
            let trait = styles.lazy.reversed().compactMap(\.1).first
            let color = role.flatMap { palette.tokens[$0] } ?? palette.foreground
            var f = font
            if let trait {
                f = NSFontManager.shared.convert(font, toHaveTrait: trait == .bold ? .boldFontMask : .italicFontMask)
            }
            out.append(NSAttributedString(string: unescape(text), attributes: [.font: f, .foregroundColor: color.nsColor]))
        }

        while let i = rest.firstIndex(of: "<") {
            append(rest[..<i])
            if rest[i...].hasPrefix("</span>") {
                if !styles.isEmpty { styles.removeLast() }
                rest = rest[rest.index(i, offsetBy: 7)...]
            } else {
                let end = rest[i...].firstIndex(of: ">") ?? rest.index(before: rest.endIndex)
                let cls = classAttribute(rest[i...end]) ?? ""
                styles.append((HighlightScopes.role(forClass: cls), HighlightScopes.trait(forClass: cls)))
                rest = rest[rest.index(after: end)...]
            }
        }
        append(rest)
        return out
    }

    private static func classAttribute(_ tag: Substring) -> Substring? {
        guard let start = tag.range(of: "class=\"")?.upperBound,
              let end = tag[start...].firstIndex(of: "\"") else { return nil }
        return tag[start..<end]
    }

    static func unescape(_ s: some StringProtocol) -> String {
        guard s.contains("&") else { return String(s) }
        return s.replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
