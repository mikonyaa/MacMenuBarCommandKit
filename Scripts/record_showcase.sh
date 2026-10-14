#!/bin/zsh

# Assembles a GIF from captured PNGs; it does not record application interaction.
set -euo pipefail

ROOT="${0:A:h:h}"
python3 "$ROOT/Tools/render_preview_assets.py"

echo "Assembled PNG captures into $ROOT/Assets/GIFs/mac-menu-bar-command-kit.gif"
echo "$ROOT/Assets/Screenshots"
