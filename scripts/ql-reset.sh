#!/bin/zsh
# Clears Quick Look generator and thumbnail caches so changed extensions are picked up.
set -euo pipefail
qlmanage -r
qlmanage -r cache
