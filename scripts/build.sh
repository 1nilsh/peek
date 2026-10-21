#!/bin/zsh
# Generates the Xcode project and builds a Debug Peek.app into build/.
set -euo pipefail
cd "${0:A:h}/.."
if [[ ! -f Config/Signing.local.xcconfig ]]; then
  echo "Missing Config/Signing.local.xcconfig. Create it with: DEVELOPMENT_TEAM = <your team ID>" >&2
  exit 1
fi
xcodegen generate --quiet
xcodebuild -project Peek.xcodeproj -scheme Peek -configuration Debug -derivedDataPath build -destination "platform=macOS,arch=$(uname -m)" -quiet build
echo "Built: build/Build/Products/Debug/Peek.app"
