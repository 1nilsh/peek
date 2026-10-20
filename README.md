# Peek

Quick Look previews and Finder thumbnails for Markdown and source code on macOS 26.

## Layout

| Path | Contents |
|---|---|
| `project.yml` | XcodeGen spec; generates `Peek.xcodeproj` (not checked in) |
| `App/` | Host app (settings, setup help) |
| `Extensions/Preview/` | Quick Look preview extension (data-based, returns HTML) |
| `Extensions/Thumbnail/` | Quick Look thumbnail extension (draws styled text) |
| `PeekKit/` | Swift package with all rendering logic |
| `Fixtures/` | Sample files for manual testing |
| `scripts/` | Build and Quick Look helper scripts |

## Build

Requires Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
scripts/build.sh                         # → build/Build/Products/Debug/Peek.app
open build/Build/Products/Debug/Peek.app # registers the extensions
scripts/ql-status.sh                     # check registration
qlmanage -p Fixtures/sample.swift        # preview from the command line
```

`PeekKit` tests run standalone: `cd PeekKit && swift test`.

## License

MIT. See `THIRD_PARTY_NOTICES.md` for bundled dependencies.
