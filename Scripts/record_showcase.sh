#!/bin/zsh

set -euo pipefail

ROOT="${0:A:h:h}"
python3 "$ROOT/Tools/render_preview_assets.py"

echo "$ROOT/Assets/GIFs/mac-menu-bar-command-kit.gif"
echo "$ROOT/Assets/Screenshots"
