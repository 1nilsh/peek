import AppKit
import Foundation
import PeekCore
import Testing
@testable import PeekHighlight

@Suite(.serialized) struct HighlighterTests {
    @Test func highlightsKnownLanguage() {
        let r = Highlighter.shared.highlight("let x = 1", language: "swift")
        #expect(r.language == "swift")
        #expect(r.html.contains("hljs-keyword"))
    }

    @Test func escapesWithoutAutoDetect() {
        let r = Highlighter.shared.highlight("<b>&</b>", language: "nope", autoDetect: false)
        #expect(r.language == nil)
        #expect(r.html == "&lt;b&gt;&amp;&lt;/b&gt;")
    }

    @Test func autoDetectsUnknownLanguage() {
        let r = Highlighter.shared.highlight("def f(x):\n    return x * 2\n", language: nil)
        #expect(r.language != nil)
    }

    @Test func loadsExtraLanguages() {
        #expect(Highlighter.shared.supports("nix"))
        #expect(Highlighter.shared.supports("dockerfile"))
        #expect(Highlighter.shared.supports("py"))
        #expect(!Highlighter.shared.supports("nope"))
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["PEEK_BENCH"] != nil), arguments: [10_000, 200_000, 500_000])
    func timing(bytes: Int) {
        let snippet = """
            struct Point { var x: Double; var y: Double }
            func distance(_ a: Point, _ b: Point) -> Double { ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot() }
            // comment with "string" and 42

            """
        let code = String(repeating: snippet, count: bytes / snippet.utf8.count + 1)
        let clock = ContinuousClock()
        let explicit = clock.measure { _ = Highlighter.shared.highlight(code, language: "swift") }
        let auto = clock.measure { _ = Highlighter.shared.highlight(code, language: nil) }
        print("[bench] \(bytes) bytes: explicit \(explicit), auto (sampled) \(auto)")
    }
}

@Suite struct HighlightedHTMLTests {
    @Test func splitsLinesWithBalancedSpans() {
        let html = "a<span class=\"hljs-comment\">/* x\ny */</span>b\nc"
        #expect(HighlightedHTML.lines(html) == [
            #"a<span class="hljs-comment">/* x</span>"#,
            #"<span class="hljs-comment">y */</span>b"#,
            "c",
        ])
    }

    @Test func attributedStringUsesRoleColorsAndUnescapes() {
        let palette = Theme.xcode.light
        let html = #"<span class="hljs-keyword">let</span> s = <span class="hljs-string">&quot;&lt;&amp;&gt;&quot;</span>"#
        let s = HighlightedHTML.attributedString(html, palette: palette, font: .systemFont(ofSize: 12))
        #expect(s.string == #"let s = "<&>""#)
        let keyword = s.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        let plain = s.attribute(.foregroundColor, at: 4, effectiveRange: nil) as? NSColor
        #expect(keyword == palette.tokens[.keyword]?.nsColor)
        #expect(plain == palette.foreground.nsColor)
    }

    @Test func subScopeOverridesBaseRole() {
        #expect(HighlightScopes.role(forClass: "hljs-title class_") == .type)
        #expect(HighlightScopes.role(forClass: "hljs-title function_") == .title)
        #expect(HighlightScopes.role(forClass: "hljs-string") == .string)
        #expect(HighlightScopes.role(forClass: "other") == nil)
    }
}
