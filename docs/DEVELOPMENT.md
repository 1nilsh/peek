# Development

## Layout

| Path | Contents |
|---|---|
| `project.yml` | XcodeGen spec; generates `Peek.xcodeproj` (not checked in) |
| `App/` | Host app: setup help, settings with live preview, supported types, file checker |
| `Extensions/Preview/` | Quick Look preview extension (data-based, returns HTML) |
| `Extensions/Thumbnail/` | Quick Look thumbnail extension (draws styled text) |
| `PeekKit/` | Swift package with all rendering logic |
| `Fixtures/` | Sample files for tests; `Fixtures/samples/` is also bundled for the app's live preview |
| `docs/` | Development, testing and release docs; README assets |
| `scripts/` | Build, release and Quick Look helper scripts |

## Build

Requires Xcode 27, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) and an Apple developer team for signing:

```sh
echo 'DEVELOPMENT_TEAM = <your team ID>' > Config/Signing.local.xcconfig   # gitignored
```

```sh
scripts/build.sh                         # → build/Build/Products/Debug/Peek.app
open build/Build/Products/Debug/Peek.app # registers the extensions
scripts/ql-status.sh                     # check registration
qlmanage -p Fixtures/samples/sample.swift   # preview from the command line
```

`PeekKit` tests run standalone: `cd PeekKit && swift test`. Manual Quick Look checks: [TESTING.md](TESTING.md). Releases: [RELEASING.md](RELEASING.md).

## Architecture

Both extensions are thin wrappers around `FormatRegistry` (`PeekKit/Sources/PeekFormats`), which maps a file's content type to a `FormatRenderer`. A renderer returns HTML for the preview and an `NSAttributedString` for the thumbnail page.

| Module | Role |
|---|---|
| `PeekCore` | `FormatRenderer` protocol, settings (App Group), themes, HTML page, text file reading, thumbnail page |
| `PeekHighlight` | highlight.js in JavaScriptCore; highlighted HTML → lines / attributed string |
| `Formats/*` | One module per format |
| `PeekFormats` | `FormatRegistry` |

Quick Look caches thumbnails keyed on file size and modification date, so settings changes don't reach existing thumbnails. Appearance changes don't either: Finder requests no new thumbnails when the system switches between light and dark, and the thumbnail extension has no `NSApp` whose appearance it could follow (verified on macOS 26.6). Thumbnails are therefore light or dark by setting. There is no API to invalidate the cache; the app's Refresh button runs `qlmanage -r cache`, which works from the sandbox. Finder also keeps thumbnails in memory, so the app then quits Finder via Apple Event (the sandbox blocks signals, so no `killall`) and relaunches it.

### Security

Quick Look's data-based HTML previews run JavaScript, allow network access and ignore Content-Security-Policy (verified on macOS 26.6). Renderers therefore never emit untrusted markup unfiltered:

- Source code and front matter are always escaped.
- Raw HTML in Markdown is, depending on the `rawHTML` setting, either sanitized by an allowlist (`HTMLSanitizer`, default) or shown as text. Sanitizing removes scripts, styles, event handlers, embedded frames and remote resources.
- Links keep only `http`, `https`, `mailto` and relative targets. Remote images load only if `allowRemoteImages` is enabled.

The preview extension may read any file (`temporary-exception.files.absolute-path.read-only`) so Markdown can embed local images. The host app has `network.client` because `WKWebView` (live preview, JavaScript disabled) doesn't launch in a sandboxed app without it, and may send Apple Events to Finder only (`temporary-exception.apple-events`, `automation.apple-events`) to relaunch it; macOS asks the user on first use. It reads files the user picks (`files.user-selected.read-only`) for Check File's open panel.

### Adding a format

1. Create `PeekKit/Sources/Formats/<Name>/` with a type conforming to `FormatRenderer`; add the target to `Package.swift` and as a dependency of `PeekFormats`.
2. Append the renderer to `FormatRegistry.renderers`.
3. List its content types under `QLSupportedContentTypes` in `project.yml`. Types macOS doesn't declare go into `UTImportedTypeDeclarations` of the app target; so do `bz.nils.peek.*` subtypes for extensions missing from a type macOS does declare.
4. `swift test` fails if the registry and `project.yml` disagree.

### Content type caveats

- Supported types are fixed at build time; Quick Look can't be extended at runtime.
- Some extensions are owned by system types and can't be claimed, e.g. `.ts` (MPEG-2 transport stream) and `.txt`.
- Quick Look dispatches on exact content type identifiers, not conformance: every type must be listed.
- An imported declaration can't add extensions to a type that is already declared. `net.daringfireball.markdown` (macOS: `md`, `markdown`) and `org.scala-lang.scala-source` (`scala`) are, so `.mdown`, `.mkd`, `.mkdn` belong to `bz.nils.peek.markdown` and `.sc` to `bz.nils.peek.source.scala`, each conforming to the original type.
- An app exporting a type for an extension overrides Peek's imported declaration; if Peek doesn't list that identifier, the file isn't previewed by Peek. Example: Adobe Creative Cloud declares `com.adobe.edn`, which takes `.edn` from `bz.nils.peek.source.clojure`.
- Thumbnails for some types always come from macOS (verified on macOS 26.6): `public.json` from `/System/Library/QuickLook/Text.qlgenerator`, `net.daringfireball.markdown` and `public.assembly-source` from Apple's `TextThumbnailExtension`. Neither appears in System Settings or `pluginkit`, so they can't be disabled. Previews of these types are Peek's. `bz.nils.peek.markdown` files get Peek's thumbnail. The list is `FormatRegistry.systemThumbnailTypes`; the app's Supported Types and Check File show it, and its live preview shows no thumbnail for these types.
