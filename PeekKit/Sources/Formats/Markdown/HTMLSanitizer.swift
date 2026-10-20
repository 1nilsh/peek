import PeekCore

/// Allowlist sanitizer for raw HTML fragments in Markdown. Quick Look ignores CSP, runs scripts and allows
/// network access (verified), so untrusted HTML must not reach the page unfiltered.
///
/// Output is rebuilt from parsed tokens rather than copied: allowed tags are re-emitted with allowed,
/// re-escaped attributes; everything else is dropped. Text is passed through with `<`/`>` escaped.
enum HTMLSanitizer {
    static let allowedElements: Set<String> = [
        "a", "abbr", "b", "bdi", "bdo", "blockquote", "br", "caption", "center", "cite", "code", "col", "colgroup",
        "dd", "del", "details", "dfn", "div", "dl", "dt", "em", "figcaption", "figure", "h1", "h2", "h3", "h4", "h5",
        "h6", "hr", "i", "img", "ins", "kbd", "li", "mark", "ol", "p", "pre", "q", "rp", "rt", "ruby", "s", "samp",
        "small", "span", "strike", "strong", "sub", "summary", "sup", "table", "tbody", "td", "tfoot", "th", "thead",
        "tr", "tt", "u", "ul", "var", "wbr",
    ]

    /// Dropped together with their content.
    static let droppedWithContent: Set<String> = [
        "script", "style", "iframe", "frame", "frameset", "object", "embed", "applet", "noscript", "noembed",
        "noframes", "template", "textarea", "title", "xmp", "plaintext", "svg", "math", "select",
    ]

    static let allowedAttributes: Set<String> = [
        "align", "valign", "title", "lang", "dir", "width", "height", "colspan", "rowspan", "span", "open",
        "start", "reversed", "alt", "href", "src", "cite", "datetime",
    ]

    static let voidElements: Set<String> = ["br", "hr", "img", "wbr", "col"]

    /// - Parameter resolveImage: Maps an `<img src>` to a safe `src`, or nil to replace the image by a placeholder.
    static func sanitize(_ html: String, resolveImage: (String) -> String?) -> String {
        var out = ""
        var dropping: String?
        var i = html.startIndex
        while i < html.endIndex {
            guard html[i] == "<" else {
                let next = html[i...].firstIndex(of: "<") ?? html.endIndex
                if dropping == nil { out += html[i..<next].replacingOccurrences(of: ">", with: "&gt;") }
                i = next
                continue
            }
            guard let (token, next) = Token.parse(html, at: i) else {
                if dropping == nil { out += "&lt;" }
                i = html.index(after: i)
                continue
            }
            i = next
            switch token {
            case .ignored:
                break
            case .end(let name):
                if let d = dropping {
                    if d == name { dropping = nil }
                } else if allowedElements.contains(name) && !voidElements.contains(name) {
                    out += "</\(name)>"
                }
            case .start(let name, let attributes, let selfClosing):
                guard dropping == nil else { break }
                if droppedWithContent.contains(name) {
                    if !selfClosing { dropping = name }
                } else if allowedElements.contains(name) {
                    out += startTag(name, attributes, resolveImage: resolveImage)
                }
            }
        }
        return out
    }

    private static func startTag(_ name: String, _ attributes: [(String, String)], resolveImage: (String) -> String?) -> String {
        var kept: [(String, String)] = []
        for (key, value) in attributes where allowedAttributes.contains(key) {
            switch key {
            case "href", "cite":
                if URLPolicy.isSafeLink(value) { kept.append((key, value)) }
            case "src":
                guard name == "img" else { continue }
                guard let src = resolveImage(value) else {
                    let alt = attributes.first { $0.0 == "alt" }?.1 ?? "image"
                    return "<span class=\"peek-missing-image\" title=\"\(value.htmlEscaped)\">\(alt.htmlEscaped)</span>"
                }
                kept.append((key, src))
            default:
                kept.append((key, value))
            }
        }
        if name == "img", !kept.contains(where: { $0.0 == "src" }) { return "" }
        return "<\(name)" + kept.map { " \($0.0)=\"\($0.1.htmlEscaped)\"" }.joined() + ">"
    }

    enum Token {
        case start(String, [(String, String)], selfClosing: Bool)
        case end(String)
        /// Comments, doctypes, processing instructions.
        case ignored

        /// Parses the tag starting at `start` (a `<`). Returns nil if it isn't a tag, so `<` is literal text.
        static func parse(_ s: String, at start: String.Index) -> (Token, String.Index)? {
            var i = s.index(after: start)
            guard i < s.endIndex else { return nil }
            if s[i...].hasPrefix("!--") {
                let end = s[i...].range(of: "-->")?.upperBound ?? s.endIndex
                return (.ignored, end)
            }
            if s[i] == "!" || s[i] == "?" {
                let end = s[i...].firstIndex(of: ">").map(s.index(after:)) ?? s.endIndex
                return (.ignored, end)
            }
            let isEnd = s[i] == "/"
            if isEnd { i = s.index(after: i) }
            guard i < s.endIndex, s[i].isASCII, s[i].isLetter else { return nil }
            let nameEnd = s[i...].firstIndex { !($0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-")) } ?? s.endIndex
            let name = s[i..<nameEnd].lowercased()
            i = nameEnd

            var attributes: [(String, String)] = []
            var selfClosing = false
            while i < s.endIndex {
                let c = s[i]
                if c == ">" {
                    let token: Token = isEnd ? .end(name) : .start(name, attributes, selfClosing: selfClosing)
                    return (token, s.index(after: i))
                }
                if c.isWhitespace || c == "/" {
                    selfClosing = c == "/"
                    i = s.index(after: i)
                    continue
                }
                selfClosing = false
                let keyEnd = s[i...].firstIndex { $0.isWhitespace || $0 == "/" || $0 == ">" || $0 == "=" } ?? s.endIndex
                let key = s[i..<keyEnd].lowercased()
                i = keyEnd
                while i < s.endIndex, s[i].isWhitespace { i = s.index(after: i) }
                var value = ""
                if i < s.endIndex, s[i] == "=" {
                    i = s.index(after: i)
                    while i < s.endIndex, s[i].isWhitespace { i = s.index(after: i) }
                    guard i < s.endIndex else { return nil }
                    if s[i] == "\"" || s[i] == "'" {
                        let quote = s[i]
                        let valueStart = s.index(after: i)
                        guard let valueEnd = s[valueStart...].firstIndex(of: quote) else { return nil }
                        value = String(s[valueStart..<valueEnd])
                        i = s.index(after: valueEnd)
                    } else {
                        let valueEnd = s[i...].firstIndex { $0.isWhitespace || $0 == ">" } ?? s.endIndex
                        value = String(s[i..<valueEnd])
                        i = valueEnd
                    }
                }
                attributes.append((key, Entities.decode(value)))
            }
            return nil
        }
    }
}

/// Which link targets may appear in `href`. The browser sees exactly the string checked here,
/// because attribute values are re-escaped on output.
enum URLPolicy {
    static let allowedSchemes: Set<String> = ["http", "https", "mailto"]

    static func isSafeLink(_ url: String) -> Bool {
        guard let scheme = scheme(of: url) else { return true }
        return allowedSchemes.contains(scheme)
    }

    /// Scheme as a URL parser sees it: tabs/newlines removed, leading/trailing controls and spaces trimmed.
    static func scheme(of url: String) -> String? {
        let cleaned = url.unicodeScalars
            .filter { $0 != "\t" && $0 != "\n" && $0 != "\r" }
            .drop { $0.value <= 0x20 }
        let chars = String(String.UnicodeScalarView(cleaned))
        guard let colon = chars.firstIndex(of: ":") else { return nil }
        let candidate = chars[..<colon]
        guard let first = candidate.first, first.isASCII, first.isLetter,
              candidate.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "+.-".contains($0)) })
        else { return nil }
        return candidate.lowercased()
    }
}

enum Entities {
    static let named: [String: String] = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{A0}"]

    /// Decodes numeric and common named character references (with semicolon).
    static func decode(_ s: String) -> String {
        guard s.contains("&") else { return s }
        var out = ""
        var rest = s[...]
        while let amp = rest.firstIndex(of: "&") {
            out += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            if let semi = after.prefix(10).firstIndex(of: ";") {
                let ref = after[..<semi]
                var decoded: String?
                if ref.hasPrefix("#x") || ref.hasPrefix("#X") {
                    decoded = UInt32(ref.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String($0) }
                } else if ref.hasPrefix("#") {
                    decoded = UInt32(ref.dropFirst()).flatMap(Unicode.Scalar.init).map { String($0) }
                } else {
                    decoded = named[String(ref)]
                }
                if let decoded {
                    out += decoded
                    rest = after[after.index(after: semi)...]
                    continue
                }
            }
            out += "&"
            rest = after
        }
        return out + rest
    }
}
