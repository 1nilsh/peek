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

    /// Auto-detection runs every grammar and is ~12× slower than explicit highlighting, so it only sees a sample.
    public static let detectionSampleSize = 10_000

    private let lock = NSLock()
    private let context: JSContext
    private let highlightFunction: JSValue

    private init() {
        guard
            let core = Bundle.module.url(forResource: "highlight.min", withExtension: "js"),
            let context = JSContext()
        else { fatalError("highlight.js resource missing") }
        context.evaluateScript("var console = { log() {}, warn() {}, error() {} };")
        let languages = Bundle.module.urls(forResourcesWithExtension: "js", subdirectory: "languages") ?? []
        for url in [core] + languages.sorted(by: { $0.path < $1.path }) {
            if let source = try? String(contentsOf: url, encoding: .utf8) { context.evaluateScript(source) }
        }
        self.context = context
        self.highlightFunction = context.evaluateScript("""
            (function (code, lang, sampleSize) {
              if (!(lang && hljs.getLanguage(lang))) {
                if (sampleSize <= 0) return null;
                lang = hljs.highlightAuto(code.slice(0, sampleSize)).language;
                if (!lang) return null;
              }
              return { html: hljs.highlight(code, { language: lang, ignoreIllegals: true }).value, language: lang };
            })
            """)
    }

    public var languages: [String] {
        lock.withLock { context.evaluateScript("hljs.listLanguages()").toArray() as? [String] ?? [] }
    }

    /// Whether `name` is a known language or alias.
    public func supports(_ name: String) -> Bool {
        lock.withLock {
            context.objectForKeyedSubscript("hljs").invokeMethod("getLanguage", withArguments: [name])?.isObject == true
        }
    }

    /// Highlights `code` as `language`; if nil or unknown, detects the language from a sample unless `autoDetect` is false.
    public func highlight(_ code: String, language: String?, autoDetect: Bool = true) -> HighlightResult {
        let sample = autoDetect ? Self.detectionSampleSize : 0
        let result = lock.withLock {
            highlightFunction.call(withArguments: [code, language ?? NSNull(), sample])
        }
        guard let result, result.isObject,
              let html = result.forProperty("html").toString()
        else { return HighlightResult(html: code.htmlEscaped, language: nil) }
        return HighlightResult(html: html, language: result.forProperty("language").toString())
    }
}
