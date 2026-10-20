import Foundation
import JavaScriptCore
import PeekCore

public struct HighlightResult: Sendable {
    /// HTML with `hljs-*` span classes; safe to embed inside `<pre><code>`.
    public let html: String
    /// Language actually used, or nil if the code was only escaped.
    public let language: String?
}

/// Runs highlight.js inside JavaScriptCore. JSContext is not thread-safe, so calls are serialized.
public final class Highlighter: @unchecked Sendable {
    public static let shared = Highlighter()

    private let lock = NSLock()
    private let context: JSContext
    private let highlightFunction: JSValue

    private init() {
        guard
            let url = Bundle.module.url(forResource: "highlight.min", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8),
            let context = JSContext()
        else { fatalError("highlight.js resource missing") }
        context.evaluateScript(source)
        self.context = context
        self.highlightFunction = context.evaluateScript("""
            (function (code, lang, auto) {
              var r;
              if (lang && hljs.getLanguage(lang)) r = hljs.highlight(code, { language: lang, ignoreIllegals: true });
              else if (auto) r = hljs.highlightAuto(code);
              else return null;
              return { html: r.value, language: r.language || lang };
            })
            """)
    }

    public var languages: [String] {
        lock.withLock { context.evaluateScript("hljs.listLanguages()").toArray() as? [String] ?? [] }
    }

    /// Highlights `code` as `language`; falls back to auto-detection if `language` is nil or unknown and `autoDetect` is set.
    public func highlight(_ code: String, language: String?, autoDetect: Bool = true) -> HighlightResult {
        let result = lock.withLock {
            highlightFunction.call(withArguments: [code, language ?? NSNull(), autoDetect])
        }
        guard let result, result.isObject,
              let html = result.forProperty("html").toString()
        else { return HighlightResult(html: code.htmlEscaped, language: nil) }
        let lang = result.forProperty("language")
        return HighlightResult(html: html, language: lang?.isString == true ? lang?.toString() : nil)
    }
}
