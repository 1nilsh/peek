# Testing

## Automated

```sh
cd PeekKit && swift test
```

Covers rendering, settings, the HTML sanitizer (known XSS payloads), every fixture, and that `FormatRegistry` matches `QLSupportedContentTypes` and the imported types in `project.yml`. `PEEK_BENCH=1` adds highlighter timings.

## Manual

Quick Look behaviour (which extension wins a type, JavaScript, CSP, network, caching) can only be checked on a real system. Run this list before a release and after changes to `project.yml`, the extensions or the renderers.

### Setup

```sh
scripts/build.sh
open build/Build/Products/Debug/Peek.app   # registers the extensions and type declarations
scripts/ql-status.sh                       # both extensions listed
scripts/ql-reset.sh
scripts/make-large-fixture.sh              # build/fixtures/large.swift
```

Preview with `qlmanage -p <file>` or Space in Finder. The extension logs each render: `log show --last 5m --info --predicate 'subsystem == "bz.nils.peek"'`.

### Source code

| File | Expected |
|---|---|
| `Fixtures/samples/sample.swift`, `.py`; `Fixtures/sample.json`, `.yaml`, `.s` | Peek: highlighted, follows light/dark (Appearance: System) |
| `Fixtures/sample.go` | Peek (type imported by Peek) |
| `Fixtures/sample.vue` | Peek (type declared by Peek) |
| `build/fixtures/large.swift` | Peek, fast, ends with "Showing … of 1 MB." |
| `Fixtures/sample.txt`, `Fixtures/sample.plist`, any `.svg` | Apple's preview, not Peek |

### Markdown

`Fixtures/samples/sample.md`:

- [ ] Front matter table (`title`, `tags`)
- [ ] Emphasis, strong, strikethrough, inline code, bare URL as link
- [ ] Task list checkboxes, aligned table, highlighted Swift block
- [ ] Teal "Peek fixture" image

`Fixtures/security/images-and-links.md` and `Fixtures/security/raw-html.md`: each item states its expected result.

### Thumbnails

Finder icon view on `Fixtures/`: highlighted text on a white page for Peek's types; dark page with Dark thumbnails on. Run `scripts/ql-reset.sh` after changes.

### Settings app

- [ ] Setup: button opens Login Items & Extensions
- [ ] Appearance: theme, appearance, font, size, wrap, line numbers update the live preview; Dark thumbnails updates the thumbnail; Refresh… asks to confirm, prompts once to control Finder, relaunches Finder with updated thumbnails; Light/Dark switch (disabled unless Appearance is System); thumbnail bottom right; Restore Defaults
- [ ] Supported Types: no "Not declared on this Mac" rows
- [ ] Check File: `sample.s` → Source Code; a `.ts` file → MPEG-2 transport stream, not handled

### Settings reach Quick Look

- [ ] Theme GitHub → `sample.swift` preview changes colours
- [ ] Appearance Dark with macOS in light mode → preview dark; Light with macOS in dark mode → preview light; reset to System
- [ ] Line numbers on → numbered, normal line spacing; copied text has no numbers
- [ ] Raw HTML "Show as text" → `raw-html.md` shows HTML literally; reset to "Clean up"
