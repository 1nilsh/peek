import Foundation
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

    /// Spike S2: prints timings; not a pass/fail benchmark.
    @Test(arguments: [10_000, 500_000, 5_000_000])
    func timing(bytes: Int) {
        let snippet = """
            struct Point { var x: Double; var y: Double }
            func distance(_ a: Point, _ b: Point) -> Double { ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot() }
            // comment with "string" and 42

            """
        let code = String(repeating: snippet, count: bytes / snippet.utf8.count + 1)
        let clock = ContinuousClock()
        let explicit = clock.measure { _ = Highlighter.shared.highlight(code, language: "swift") }
        let auto = bytes <= 500_000 ? clock.measure { _ = Highlighter.shared.highlight(code, language: nil) } : nil
        print("[S2] \(bytes) bytes: explicit \(explicit), auto \(auto.map(String.init(describing:)) ?? "skipped")")
    }
}
