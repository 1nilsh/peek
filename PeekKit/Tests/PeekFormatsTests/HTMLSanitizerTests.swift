import Foundation
import Markdown
import PeekCore
import Testing
@testable import PeekMarkdown

@Suite struct HTMLSanitizerTests {
    func clean(_ html: String, images: (String) -> String? = { _ in nil }) -> String {
        HTMLSanitizer.sanitize(html, resolveImage: images)
    }

    /// Nothing that can execute script or fetch a resource may survive.
    func assertInert(_ html: String, sourceLocation: Testing.SourceLocation = #_sourceLocation) {
        let out = clean(html).lowercased()
        for needle in ["<script", "<style", "<iframe", "<svg", "<link", "<meta", "<base", "<object", "<embed", "<form",
                       " on", "javascript:", "vbscript:", "style=", "srcset", "<img"] {
            #expect(!out.contains(needle), "\(needle) survived in \(out)", sourceLocation: sourceLocation)
        }
    }

    @Test(arguments: [
        "<script>alert(1)</script>",
        "<SCRIPT SRC=//x.y/z.js></SCRIPT>",
        "<scr<script>ipt>alert(1)</script>",
        "<img src=x onerror=alert(1)>",
        "<img src=\"https://evil.example/pixel.gif\">",
        "<svg/onload=alert(1)>",
        "<svg><script>alert(1)</script></svg>",
        "<iframe src=\"https://evil.example\"></iframe>",
        "<a href=\"javascript:alert(1)\">x</a>",
        "<a href=\"jav&#x61;script:alert(1)\">x</a>",
        "<a href=\"&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;:alert(1)\">x</a>",
        "<a href=\" \tjava\nscript:alert(1)\">x</a>",
        "<a href=\"data:text/html,<script>alert(1)</script>\">x</a>",
        "<div style=\"background:url(https://evil.example)\">x</div>",
        "<style>@import 'https://evil.example/x.css';</style>",
        "<link rel=stylesheet href=https://evil.example/x.css>",
        "<meta http-equiv=refresh content=\"0;url=https://evil.example\">",
        "<base href=\"https://evil.example/\">",
        "<object data=\"https://evil.example/x.swf\"></object>",
        "<form action=https://evil.example><input name=x></form>",
        "<picture><source srcset=\"https://evil.example/a.png\"><img src=x></picture>",
        "<details open ontoggle=alert(1)>x</details>",
        "<a href=\"x\" <script>alert(1)</script>",
        "<!--><script>alert(1)</script>-->",
    ])
    func neutralisesPayload(_ payload: String) {
        assertInert(payload)
    }

    @Test func keepsCommonReadmeMarkup() {
        let html = #"<p align="center"><img src="logo.png" width="120" alt="Logo"></p><details><summary>More</summary>Text<br/></details>"#
        #expect(clean(html) { "cid:\($0)" } == #"<p align="center"><img src="cid:logo.png" width="120" alt="Logo"></p><details><summary>More</summary>Text<br></details>"#)
    }

    @Test func keepsSafeLinks() {
        #expect(clean(#"<a href="https://e.com/?a=1&amp;b=2" title="t">x</a>"#) == #"<a href="https://e.com/?a=1&amp;b=2" title="t">x</a>"#)
        #expect(clean(#"<a href="docs/x.md#y">x</a>"#) == #"<a href="docs/x.md#y">x</a>"#)
        #expect(clean(#"<a href="mailto:a@b.c">x</a>"#) == #"<a href="mailto:a@b.c">x</a>"#)
    }

    @Test func replacesUnresolvedImagesWithPlaceholder() {
        #expect(clean(#"<img src="https://e.com/a.png" alt="A">"#)
            == #"<span class="peek-missing-image" title="https://e.com/a.png">A</span>"#)
    }

    @Test func escapesStrayAngleBrackets() {
        #expect(clean("a < b > c") == "a &lt; b &gt; c")
    }
}

@Suite struct MarkdownRawHTMLTests {
    func render(_ markdown: String, mode: Settings.RawHTMLMode) -> String {
        var walker = MarkdownHTML(baseURL: URL(filePath: "/tmp"), allowRemoteImages: false, rawHTML: mode)
        walker.visit(Document(parsing: markdown))
        return walker.result
    }

    @Test func sanitizesInlineAndBlockHTML() {
        let html = render("Hi <b onclick=\"x()\">there</b>\n\n<div>\n<script>alert(1)</script>\n</div>\n", mode: .sanitize)
        #expect(html.contains("<b>there</b>"))
        #expect(!html.contains("script"))
        #expect(!html.contains("onclick"))
    }

    @Test func escapesInEscapeMode() {
        let html = render("Hi <b>there</b>\n\n<div>x</div>\n", mode: .escape)
        #expect(html.contains("&lt;b&gt;there&lt;/b&gt;"))
        #expect(html.contains("<pre class=\"raw-html\">&lt;div&gt;x&lt;/div&gt;"))
    }

    @Test func dropsUnsafeMarkdownLinkTargets() {
        #expect(render("[x](javascript:alert(1))", mode: .sanitize) == "<p><a>x</a></p>\n")
        #expect(render("[x](https://e.com)", mode: .escape) == "<p><a href=\"https://e.com\">x</a></p>\n")
    }
}
