/// Wraps renderer output into a complete, script-free HTML document.
public enum HTMLPage {
    public static func render(body: String, context: RenderContext, css: String = "") -> String {
        let s = context.settings
        // Quick Look currently ignores this CSP (verified: scripts run, remote loads succeed). Safety comes from
        // escaping/sanitizing in the renderers; the CSP stays as a second layer should Quick Look start enforcing it.
        let imgSrc = "cid: data:" + (s.allowRemoteImages ? " https:" : "")
        let mono = s.fontFamily.isEmpty ? "ui-monospace, SFMono-Regular, Menlo, monospace" : "\"\(s.fontFamily.htmlEscaped)\", ui-monospace, monospace"
        return """
            <!doctype html>
            <html><head><meta charset="utf-8">
            <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src \(imgSrc)">
            <style>
            \(context.theme.cssVariables)
            :root { color-scheme: light dark; --mono: \(mono); --code-size: \(s.fontSize)px; }
            html { background: var(--bg); color: var(--fg); }
            body { margin: 0; padding: 16px 20px; font: 14px/1.5 -apple-system, sans-serif; }
            pre, code { font-family: var(--mono); font-size: var(--code-size); tab-size: \(s.tabWidth); }
            pre { margin: 0; line-height: 1.45; white-space: \(s.wordWrap ? "pre-wrap" : "pre"); overflow-wrap: anywhere; }
            .peek-notice { color: var(--secondary); font-style: italic; margin: 1em 0 0; }
            \(HighlightScopes.css)
            \(css)
            </style></head>
            <body>
            \(body)
            </body></html>
            """
    }
}
