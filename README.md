# Peek

Quick Look previews and Finder thumbnails for Markdown and source code on macOS 26.

## Install

1. Download `Peek-<version>.dmg` from [Releases](https://github.com/1nilsh/peek/releases) and drag Peek into Applications.
2. Open Peek once so macOS registers its extensions.
3. Enable Peek under Quick Look in System Settings → General → Login Items & Extensions.

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

## Releasing

Pushing a tag `v<version>` runs `.github/workflows/release.yml`, which calls `scripts/release.sh <version>` (archive, Developer ID signing without provisioning profiles, DMG, notarization, stapling) and publishes `Peek-<version>.dmg` as a GitHub release.

```sh
git tag v0.1.0 && git push origin v0.1.0
```

The script also runs locally: `NOTARY_PROFILE=peek-notary scripts/release.sh 0.1.0`. `SKIP_NOTARIZE=1 SIGN_IDENTITY="Apple Development"` tests packaging without a Developer ID certificate.

### One-time setup

1. **Developer ID Application certificate** (requires the Account Holder role): Xcode → Settings → Accounts → team → Manage Certificates → + → Developer ID Application.
2. **App Store Connect API key** for notarization: [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → Team Keys → +, access "Developer". Download the `.p8` (only possible once) and note the Key ID and Issuer ID. For local use:
   ```sh
   xcrun notarytool store-credentials peek-notary --key AuthKey_<KEYID>.p8 --key-id <KEYID> --issuer <ISSUER_ID>
   ```
3. **Repository secrets** for the workflow. Export the certificate with its private key from Keychain Access (My Certificates → Developer ID Application → Export, `.p12` with a password), then:
   ```sh
   gh secret set APPLE_TEAM_ID --body <TEAM_ID>
   base64 -i developer-id.p12 | gh secret set DEVELOPER_ID_P12
   gh secret set DEVELOPER_ID_P12_PASSWORD           # prompts
   gh secret set NOTARY_KEY_P8 < AuthKey_<KEYID>.p8
   gh secret set NOTARY_KEY_ID --body <KEYID>
   gh secret set NOTARY_ISSUER_ID --body <ISSUER_ID>
   ```

## License

MIT. See `THIRD_PARTY_NOTICES.md` for bundled dependencies.
