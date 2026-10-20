#!/bin/zsh
# Builds a signed, notarized and stapled build/release/Peek-<version>.dmg.
#
#   scripts/release.sh <version>          e.g. scripts/release.sh 0.1.0
#
# Requires a "Developer ID Application" certificate in the keychain and Config/Signing.local.xcconfig.
# Notarization credentials, either:
#   NOTARY_PROFILE=<name>                               stored via `xcrun notarytool store-credentials`
#   NOTARY_KEY_PATH, NOTARY_KEY_ID, NOTARY_ISSUER_ID    App Store Connect API key
# Testing the pipeline without notarizing: SKIP_NOTARIZE=1 SIGN_IDENTITY="Apple Development".
set -euo pipefail
cd "${0:A:h}/.."

version=${1:?usage: scripts/release.sh <version>}
identity=${SIGN_IDENTITY:-Developer ID Application}
build_number=$(git rev-list --count HEAD)
out=build/release
app=$out/Peek.xcarchive/Products/Applications/Peek.app
dmg=$out/Peek-$version.dmg

notary=()
if [[ -n ${NOTARY_PROFILE:-} ]]; then
  notary=(--keychain-profile "$NOTARY_PROFILE")
elif [[ -n ${NOTARY_KEY_PATH:-} ]]; then
  notary=(--key "$NOTARY_KEY_PATH" --key-id "${NOTARY_KEY_ID:?}" --issuer "${NOTARY_ISSUER_ID:?}")
elif [[ -z ${SKIP_NOTARIZE:-} ]]; then
  echo "No notarization credentials: set NOTARY_PROFILE or NOTARY_KEY_PATH/NOTARY_KEY_ID/NOTARY_ISSUER_ID" >&2
  exit 1
fi
[[ -f Config/Signing.local.xcconfig ]] || { echo "Missing Config/Signing.local.xcconfig" >&2; exit 1; }
# Command-line settings also reach SwiftPM targets, which don't read our xcconfig; pass the team explicitly.
team=$(sed -nE 's/^DEVELOPMENT_TEAM *= *([A-Z0-9]+).*/\1/p' Config/Signing.local.xcconfig)
[[ -n $team ]] || { echo "No DEVELOPMENT_TEAM in Config/Signing.local.xcconfig" >&2; exit 1; }

rm -rf $out
mkdir -p $out

echo "==> Archiving Peek $version ($build_number), signed by \"$identity\""
xcodegen generate --quiet
# Manual signing without provisioning profiles: the team-prefixed App Group doesn't need one on macOS.
xcodebuild archive -quiet \
  -project Peek.xcodeproj -scheme Peek -configuration Release \
  -archivePath $out/Peek.xcarchive -derivedDataPath build -destination 'generic/platform=macOS' \
  MARKETING_VERSION=$version CURRENT_PROJECT_VERSION=$build_number DEVELOPMENT_TEAM=$team \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$identity" PROVISIONING_PROFILE_SPECIFIER= \
  OTHER_CODE_SIGN_FLAGS=--timestamp

codesign --verify --deep --strict $app
for bundle in $app $app/Contents/PlugIns/*.appex; do
  if codesign -d --entitlements - --xml $bundle 2>/dev/null | grep -q get-task-allow; then
    echo "$bundle has get-task-allow; notarization would fail" >&2
    exit 1
  fi
done

echo "==> Creating $dmg"
staging=$out/dmg
mkdir -p $staging
ditto $app $staging/Peek.app
ln -s /Applications $staging/Applications
hdiutil create -quiet -volname "Peek $version" -srcfolder $staging -format UDZO -ov $dmg
codesign --sign "$identity" --timestamp $dmg

if [[ -n ${SKIP_NOTARIZE:-} ]]; then
  echo "==> Skipping notarization: $dmg"
  exit 0
fi

echo "==> Notarizing (usually a few minutes)"
xcrun notarytool submit $dmg "${notary[@]}" --wait
xcrun stapler staple $dmg
spctl --assess --type open --context context:primary-signature --verbose $dmg
echo "==> Done: $dmg"
