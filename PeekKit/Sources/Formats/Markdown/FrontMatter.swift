/// YAML front matter at the start of a Markdown file, split into top-level keys without a YAML parser.
/// Nested values (lists, maps, block scalars) are kept as raw text.
struct FrontMatter: Equatable {
    struct Entry: Equatable {
        let key: String
        let value: String
    }

    let entries: [Entry]

    /// Splits `--- … ---` (or `--- … ...`) from the start of `text`.
    static func split(_ text: String) -> (frontMatter: FrontMatter?, body: Substring) {
        var lines = text[...].split(separator: "\n", omittingEmptySubsequences: false)[...]
        guard lines.first?.trimmingTrailingWhitespace == "---" else { return (nil, text[...]) }
        lines = lines.dropFirst()
        guard let end = lines.firstIndex(where: { ["---", "..."].contains($0.trimmingTrailingWhitespace) }) else {
            return (nil, text[...])
        }
        let body = lines[(end + 1)...].joined(separator: "\n")
        return (FrontMatter(entries: parse(lines[..<end])), Substring(body))
    }

    private static func parse(_ lines: ArraySlice<Substring>) -> [Entry] {
        var entries: [(key: String, value: [Substring])] = []
        for line in lines {
            let isTopLevelKey = !(line.first?.isWhitespace ?? true) && !line.hasPrefix("-") && !line.hasPrefix("#")
            if isTopLevelKey, let colon = line.firstIndex(of: ":") {
                let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                entries.append((String(line[..<colon]), value.isEmpty ? [] : [Substring(unquote(value))]))
            } else if !entries.isEmpty, !line.trimmingCharacters(in: .whitespaces).isEmpty {
                entries[entries.count - 1].value.append(line)
            }
        }
        return entries.map { Entry(key: $0.key, value: $0.value.joined(separator: "\n")) }
    }

    private static func unquote(_ s: String) -> String {
        guard s.count >= 2, let q = s.first, q == "\"" || q == "'", s.last == q else { return s }
        return String(s.dropFirst().dropLast())
    }
}

private extension Substring {
    var trimmingTrailingWhitespace: Substring {
        var s = self
        while s.last?.isWhitespace == true { s = s.dropLast() }
        return s
    }
}
