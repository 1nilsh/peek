#!/bin/zsh
# Writes build/fixtures/large.swift (~1 MB) to test truncation and highlighting speed.
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p build/fixtures
for i in {1..3000}; do cat Fixtures/samples/sample.swift; done > build/fixtures/large.swift
echo "build/fixtures/large.swift: $(wc -c < build/fixtures/large.swift) bytes"
