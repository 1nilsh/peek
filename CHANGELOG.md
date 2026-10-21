# Changelog

## [0.1.2]

### Changed

- Check File shows separately whether Peek or macOS provides the preview and the thumbnail. Supported Types has a Thumbnail column. The live preview shows no thumbnail for Markdown, whose thumbnails come from macOS.

### Fixed

- `.mdown`, `.mkd`, `.mkdn` and `.sc` files are previewed and get thumbnails. They were listed as supported but not handled.
- Check File: Choose File… opens a file panel. The settings app may now read files you pick there.

### Known limitations

- `.edn` files aren't handled on Macs with Adobe Creative Cloud installed, which declares its own type for `.edn`.

## [0.1.1] - 2026-10-21

### Added

- Appearance setting: previews follow the system or are always light or dark.
- Dark thumbnails setting.
- Thumbnail text size setting: small, medium, large, very large.
- Refresh… button under Appearance: clears the Quick Look thumbnail cache and relaunches Finder, so changed thumbnail settings apply to existing files. macOS asks once for permission to let Peek control Finder.

### Changed

- Thumbnail text is larger by default.
- The settings app may send Apple Events to Finder, only to relaunch it.

### Known limitations

- Markdown, JSON and assembly (`.s`) files get macOS's own plain-text thumbnails. macOS uses its built-in thumbnailers for these types and they can't be switched off. Previews of these files are Peek's.

## [0.1.0] - 2026-10-20

First release.

- Quick Look previews for Markdown and source code with syntax highlighting.
- Finder thumbnails showing the start of the file as highlighted text.
- Settings app with live preview: theme, font, line wrapping, line numbers, tab width, highlighting limit, Markdown front matter, raw HTML handling, remote images.
- Signed with a Developer ID and notarized.
