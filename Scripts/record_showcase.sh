#!/bin/zsh

# Assembles a GIF from captured PNGs; it does not record application interaction.
set -euo pipefail

ROOT="${0:A:h:h}"
python3 "$ROOT/Tools/render_preview_assets.py"

echo "Assembled PNG captures into $ROOT/Assets/GIFs/rc-native-content-captures.gif"
echo "$ROOT/Assets/NativeCaptures/0.3.0-rc.1"
