#!/bin/zsh
# Generates the Xcode project and builds a Debug Peek.app into build/.
set -euo pipefail
cd "${0:A:h}/.."
xcodegen generate --quiet
xcodebuild -project Peek.xcodeproj -scheme Peek -configuration Debug -derivedDataPath build -quiet build
echo "Built: build/Build/Products/Debug/Peek.app"
