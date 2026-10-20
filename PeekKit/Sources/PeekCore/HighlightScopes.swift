/// Maps highlight.js scope classes (`hljs-title class_`) to theme roles, for both CSS and attributed strings.
public enum HighlightScopes {
    static let base: [String: TokenRole] = [
        "keyword": .keyword, "selector-tag": .keyword, "doctag": .keyword,
        "built_in": .builtIn, "symbol": .builtIn, "bullet": .builtIn, "literal": .builtIn,
        "type": .type,
        "string": .string, "regexp": .string, "char": .string,
        "number": .number,
        "comment": .comment, "quote": .comment,
        "title": .title,
        "attr": .attribute, "attribute": .attribute, "property": .attribute,
        "selector-id": .attribute, "selector-class": .attribute, "selector-attr": .attribute, "selector-pseudo": .attribute,
        "variable": .variable, "template-variable": .variable,
        "meta": .meta,
        "tag": .tag, "name": .tag,
        "section": .section, "link": .link, "addition": .addition, "deletion": .deletion,
    ]

    /// Sub-scope suffixes that override the base role, e.g. `title.class` → `hljs-title class_`.
    static let sub: [String: TokenRole] = ["class_": .type, "function_": .title, "language_": .keyword]

    public enum Trait: Sendable { case italic, bold }

    public static func role(forClass attribute: some StringProtocol) -> TokenRole? {
        let parts = attribute.split(separator: " ")
        guard let first = parts.first, first.hasPrefix("hljs-") else { return nil }
        if let override = parts.dropFirst().lazy.compactMap({ sub[String($0)] }).first { return override }
        return base[String(first.dropFirst(5))]
    }

    public static func trait(forClass attribute: some StringProtocol) -> Trait? {
        switch attribute.split(separator: " ").first {
        case "hljs-emphasis": .italic
        case "hljs-strong", "hljs-section": .bold
        default: nil
        }
    }

    /// Rules referencing the `--<role>` variables from `Theme.cssVariables`.
    public static let css: String = {
        let baseRules = base.sorted { $0.key < $1.key }.map { ".hljs-\($0.key) { color: var(--\($0.value.rawValue)); }" }
        // Two-class selectors so sub-scopes beat their base scope.
        let subRules = sub.sorted { $0.key < $1.key }.map { "[class^=\"hljs-\"].\($0.key) { color: var(--\($0.value.rawValue)); }" }
        return (baseRules + subRules + [
            ".hljs-emphasis { font-style: italic; }",
            ".hljs-strong, .hljs-section { font-weight: 600; }",
        ]).joined(separator: "\n")
    }()
}
