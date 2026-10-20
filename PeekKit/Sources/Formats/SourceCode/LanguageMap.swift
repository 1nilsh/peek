import PeekHighlight
import UniformTypeIdentifiers

enum LanguageMap {
    /// Content type → highlight.js language. Every key must be listed in `QLSupportedContentTypes` (project.yml);
    /// `bz.nils.peek.source.*` and third-party types are declared there as imported types.
    static let languages: [String: String] = [
        "public.swift-source": "swift",
        "public.python-script": "python",
        "com.netscape.javascript-source": "javascript",
        "com.microsoft.typescript": "typescript",
        "public.json": "json",
        "public.yaml": "yaml",
        "public.toml": "ini",
        "com.microsoft.ini": "ini",
        "public.shell-script": "bash",
        "public.bash-script": "bash",
        "public.zsh-script": "bash",
        "public.c-source": "c",
        "public.c-header": "c",
        "public.c-plus-plus-source": "cpp",
        "public.c-plus-plus-header": "cpp",
        "public.objective-c-source": "objectivec",
        "public.objective-c-plus-plus-source": "objectivec",
        "com.microsoft.c-sharp": "csharp",
        "com.sun.java-source": "java",
        "org.kotlinlang.source": "kotlin",
        "org.golang.go-script": "go",
        "org.rust-lang.rust-script": "rust",
        "public.ruby-script": "ruby",
        "public.perl-script": "perl",
        "public.php-script": "php",
        "org.lua.lua-source": "lua",
        "org.iso.sql": "sql",
        "public.xml": "xml",
        "public.css": "css",
        "public.make-source": "makefile",
        "public.patch-file": "diff",
        "org.scala-lang.scala-source": "scala",
        "dev.dart.dart-script": "dart",
        "org.haskell.haskell-script": "haskell",
        "public.protobuf-source": "protobuf",
        "bz.nils.peek.source.javascript": "javascript",
        "bz.nils.peek.source.jsonc": "json",
        "bz.nils.peek.source.fish": "bash",
        "bz.nils.peek.source.scss": "scss",
        "bz.nils.peek.source.less": "less",
        "bz.nils.peek.source.vue": "xml",
        "bz.nils.peek.source.svelte": "xml",
        "bz.nils.peek.source.graphql": "graphql",
        "bz.nils.peek.source.cmake": "cmake",
        "bz.nils.peek.source.groovy": "groovy",
        "bz.nils.peek.source.elixir": "elixir",
        "bz.nils.peek.source.erlang": "erlang",
        "bz.nils.peek.source.ocaml": "ocaml",
        "bz.nils.peek.source.clojure": "clojure",
        "bz.nils.peek.source.nix": "nix",
        "bz.nils.peek.source.dockerfile": "dockerfile",
    ]

    /// Claimed without a fixed language; resolved by file extension or auto-detection.
    static let genericTypes = ["public.source-code"]

    /// Extensions that are not highlight.js names or aliases. Needed when another app's exported type
    /// (e.g. `org.vuejs.vue`) wins over Peek's imported one and reaches us via `public.source-code`.
    static let extensions: [String: String] = [
        "vue": "xml", "svelte": "xml", "fish": "bash", "json5": "json", "gradle": "groovy",
        "containerfile": "dockerfile", "hrl": "erlang", "mli": "ocaml", "cljs": "clojure", "cljc": "clojure",
        "edn": "clojure", "lhs": "haskell", "sc": "scala",
    ]

    static var contentTypes: [String] { Array(languages.keys) + genericTypes }

    /// nil means auto-detect.
    static func language(for type: UTType?, fileExtension: String) -> String? {
        if let id = type?.identifier, let language = languages[id] { return language }
        let ext = fileExtension.lowercased()
        if let language = extensions[ext] { return language }
        return !ext.isEmpty && Highlighter.shared.supports(ext) ? ext : nil
    }
}
