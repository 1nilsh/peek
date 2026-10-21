# Releasing

Pushing a tag `v<version>` runs `.github/workflows/release.yml`, which calls `scripts/release.sh <version>` (archive, Developer ID signing without provisioning profiles, DMG, notarization, stapling) and publishes `Peek-<version>.dmg` as a GitHub release.

```sh
git tag v0.1.0 && git push origin v0.1.0
```

The script also runs locally: `NOTARY_PROFILE=peek-notary scripts/release.sh 0.1.0`. `SKIP_NOTARIZE=1 SIGN_IDENTITY="Apple Development"` tests packaging without a Developer ID certificate.

Run the manual checks in [TESTING.md](TESTING.md) before tagging.

## One-time setup

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
