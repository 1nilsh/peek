# Peek

Quick Look previews and Finder thumbnails for Markdown and source code on macOS 26.

## Layout

| Path | Contents |
|---|---|
| `project.yml` | XcodeGen spec; generates `Peek.xcodeproj` (not checked in) |
| `App/` | Host app: setup help, settings with live preview, supported types, file checker |
| `Extensions/Preview/` | Quick Look preview extension (data-based, returns HTML) |
| `Extensions/Thumbnail/` | Quick Look thumbnail extension (draws styled text) |
| `PeekKit/` | Swift package with all rendering logic |
| `Fixtures/` | Sample files for tests; `Fixtures/samples/` is also bundled for the app's live preview |
| `docs/` | Testing checklist |
| `scripts/` | Build and Quick Look helper scripts |

## Build

Requires Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
scripts/build.sh                         # → build/Build/Products/Debug/Peek.app
open build/Build/Products/Debug/Peek.app # registers the extensions
scripts/ql-status.sh                     # check registration
qlmanage -p Fixtures/samples/sample.swift   # preview from the command line
```

`PeekKit` tests run standalone: `cd PeekKit && swift test`. Manual Quick Look checks: [docs/TESTING.md](docs/TESTING.md).

## Architecture

Both extensions are thin wrappers around `FormatRegistry` (`PeekKit/Sources/PeekFormats`), which maps a file's content type to a `FormatRenderer`. A renderer returns HTML for the preview and an `NSAttributedString` for the thumbnail page.

| Module | Role |
|---|---|
| `PeekCore` | `FormatRenderer` protocol, settings (App Group), themes, HTML page, text file reading, thumbnail page |
| `PeekHighlight` | highlight.js in JavaScriptCore; highlighted HTML → lines / attributed string |
| `Formats/*` | One module per format |
| `PeekFormats` | `FormatRegistry` |

### Security

Quick Look's data-based HTML previews run JavaScript, allow network access and ignore Content-Security-Policy (verified on macOS 26.6). Renderers therefore never emit untrusted markup unfiltered:

- Source code and front matter are always escaped.
- Raw HTML in Markdown is, depending on the `rawHTML` setting, either sanitized by an allowlist (`HTMLSanitizer`, default) or shown as text. Sanitizing removes scripts, styles, event handlers, embedded frames and remote resources.
- Links keep only `http`, `https`, `mailto` and relative targets. Remote images load only if `allowRemoteImages` is enabled.

The preview extension may read any file (`temporary-exception.files.absolute-path.read-only`) so Markdown can embed local images. The host app has `network.client` because `WKWebView` (live preview, JavaScript disabled) doesn't launch in a sandboxed app without it.

### Adding a format

1. Create `PeekKit/Sources/Formats/<Name>/` with a type conforming to `FormatRenderer`; add the target to `Package.swift` and as a dependency of `PeekFormats`.
2. Append the renderer to `FormatRegistry.renderers`.
3. List its content types under `QLSupportedContentTypes` in `project.yml`. Types macOS doesn't declare go into `UTImportedTypeDeclarations` of the app target.
4. `swift test` fails if the registry and `project.yml` disagree.

### Content type caveats

- Supported types are fixed at build time; Quick Look can't be extended at runtime.
- Some extensions are owned by system types and can't be claimed, e.g. `.ts` (MPEG-2 transport stream) and `.txt`.
- Quick Look dispatches on exact content type identifiers, not conformance: every type must be listed.
- An app exporting a type for an extension overrides Peek's imported declaration; if Peek doesn't list that identifier, the file isn't previewed by Peek.

## License

MIT. See `THIRD_PARTY_NOTICES.md` for bundled dependencies.
