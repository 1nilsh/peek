import Foundation
import OSLog
import PeekCore
import PeekHighlight
import QuickLookUI
import UniformTypeIdentifiers

private let log = Logger(subsystem: "bz.nils.peek", category: "preview")

/// Phase 0 spike: renders a diagnostic page (S1 JavaScript, S2 timing, S3 App Group, S4 type claims).
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private static let highlightLimit = 200_000

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
        let data = try Data(contentsOf: url)
        let text = String(decoding: data.prefix(Self.highlightLimit), as: UTF8.self)

        let clock = ContinuousClock()
        var result: HighlightResult?
        let elapsed = clock.measure {
            result = Highlighter.shared.highlight(text, language: url.pathExtension.lowercased())
        }
        log.info("highlighted \(data.count) bytes of \(url.lastPathComponent, privacy: .public) in \(elapsed, privacy: .public)")

        let groupValue = AppGroup.defaults?.string(forKey: "spike.lastWrite") ?? "(nothing)"
        let rows = [
            ("File", url.lastPathComponent),
            ("Content type", type?.identifier ?? "?"),
            ("Size", "\(data.count) bytes\(data.count > Self.highlightLimit ? " (truncated)" : "")"),
            ("Language", result?.language ?? "none"),
            ("Highlight time", "\(elapsed)"),
            ("App Group", "\(AppGroup.identifier) → \(groupValue)"),
        ]
        let table = rows.map { "<tr><th>\($0.0.htmlEscaped)</th><td>\($0.1.htmlEscaped)</td></tr>" }.joined()
        let html = """
            <!doctype html><html><head><meta charset="utf-8"><style>\(Self.css)</style></head><body>
            <table>\(table)<tr><th>JavaScript</th><td id="js">not running</td></tr></table>
            <script>document.getElementById('js').textContent = 'running';</script>
            <pre><code class="hljs">\(result?.html ?? "")</code></pre>
            </body></html>
            """

        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 900, height: 1000)) { reply in
            reply.stringEncoding = .utf8
            return Data(html.utf8)
        }
    }

    private static let css = """
        :root { color-scheme: light dark; font: 13px -apple-system; }
        table { border-collapse: collapse; margin-bottom: 1em; }
        th, td { text-align: left; padding: 2px 12px 2px 0; }
        pre { font: 12px ui-monospace, monospace; white-space: pre-wrap; }
        .hljs-keyword, .hljs-built_in, .hljs-literal { color: #ad3da4; }
        .hljs-string { color: #d12f1b; }
        .hljs-number { color: #272ad8; }
        .hljs-comment { color: #707f8c; }
        .hljs-title, .hljs-type { color: #3e8087; }
        @media (prefers-color-scheme: dark) {
          .hljs-keyword, .hljs-built_in, .hljs-literal { color: #ff7ab2; }
          .hljs-string { color: #ff8170; }
          .hljs-number { color: #d9c97c; }
          .hljs-comment { color: #7f8c98; }
          .hljs-title, .hljs-type { color: #78c2b3; }
        }
        """
}
