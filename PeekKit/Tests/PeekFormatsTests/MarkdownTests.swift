import Foundation
import Markdown
import PeekCore
import Testing
@testable import PeekMarkdown

@Suite struct FrontMatterTests {
    @Test func splitsTopLevelKeysAndNestedValues() {
        let text = "---\ntitle: \"Hello\"\ntags:\n  - a\n  - b\nempty:\n---\n# Body\n"
        let (fm, body) = FrontMatter.split(text)
        #expect(fm?.entries == [
            .init(key: "title", value: "Hello"),
            .init(key: "tags", value: "  - a\n  - b"),
            .init(key: "empty", value: ""),
        ])
        #expect(body == "# Body\n")
    }

    @Test func ignoresUnterminatedOrMissingFrontMatter() {
        #expect(FrontMatter.split("---\ntitle: x\n").frontMatter == nil)
        #expect(FrontMatter.split("# Title\n---\n").frontMatter == nil)
    }
}

@Suite struct MarkdownHTMLTests {
    let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures/samples")

    func render(_ markdown: String, remote: Bool = false) -> MarkdownHTML {
        var walker = MarkdownHTML(baseURL: fixtures, allowRemoteImages: remote)
        walker.visit(Document(parsing: markdown))
        return walker
    }

    @Test func rendersGFMBlocks() {
        let html = render("| a | b |\n|:-|-:|\n| 1 | 2 |\n\n- [x] done\n- [ ] todo\n\n~~gone~~").result
        #expect(html.contains("<th style=\"text-align: left\">a</th>"))
        #expect(html.contains("<td style=\"text-align: right\">2</td>"))
        #expect(html.contains("<li class=\"task\"><input type=\"checkbox\" disabled checked>"))
        #expect(html.contains("<del>gone</del>"))
    }

    @Test func highlightsFencedCode() {
        let html = render("```swift\nlet x = 1\n```").result
        #expect(html.contains("data-language=\"swift\""))
        #expect(html.contains("hljs-keyword"))
    }

    @Test func autolinksBareURLsButNotInsideLinks() {
        #expect(MarkdownHTML.autolinked("see https://example.com/a?b=1&c. ok")
            == "see <a href=\"https://example.com/a?b=1&amp;c\">https://example.com/a?b=1&amp;c</a>. ok")
        let html = render("[https://x.org](https://x.org)").result
        #expect(html == "<p><a href=\"https://x.org\">https://x.org</a></p>\n")
    }

    @Test func escapesAttributes() {
        let html = render("[x](https://e.com/\"onmouseover=\"y)").result
        #expect(!html.contains("\"onmouseover"))
    }

    @Test func embedsLocalImagesOnce() {
        let walker = render("![one](sample.png) ![two](./sample.png)")
        #expect(walker.attachments.count == 1)
        #expect(walker.attachments["img0"]?.contentType == .png)
        #expect(walker.result.contains("<img src=\"cid:img0\" alt=\"one\">"))
        #expect(walker.result.contains("<img src=\"cid:img0\" alt=\"two\">"))
    }

    @Test func blocksRemoteImagesUnlessAllowed() {
        #expect(render("![r](https://e.com/i.png)").result.contains("peek-missing-image"))
        #expect(render("![r](https://e.com/i.png)", remote: true).result.contains("<img src=\"https://e.com/i.png\""))
    }

    @Test func marksMissingImages() {
        #expect(render("![gone](nope.png)").result.contains("<span class=\"peek-missing-image\" title=\"nope.png\">gone</span>"))
    }
}

@Suite struct MarkdownRendererTests {
    let sample = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures/samples/sample.md")

    @Test func previewShowsFrontMatterTableAndBody() throws {
        let doc = try MarkdownRenderer().preview(of: sample, context: RenderContext(settings: Settings(), contentType: nil))
        #expect(doc.html.contains("<table class=\"front-matter\">"))
        #expect(doc.html.contains("<h1>Heading</h1>"))
        #expect(doc.attachments.count == 1)
    }

    @Test func frontMatterCanBeHidden() throws {
        var settings = Settings()
        settings.showFrontMatter = false
        let doc = try MarkdownRenderer().preview(of: sample, context: RenderContext(settings: settings, contentType: nil))
        #expect(!doc.html.contains("front-matter\">"))
    }
}
