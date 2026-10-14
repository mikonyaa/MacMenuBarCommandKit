#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 || "$1" != /* ]]; then echo "usage: $0 <absolute-owned-tools-directory>" >&2; exit 2; fi
commandkit_tools="$1"
mkdir -p "$commandkit_tools/xcodegen" "$commandkit_tools/swiftlint"
curl --fail --location --silent --show-error \
  https://github.com/yonaskolb/XcodeGen/releases/download/2.45.4/xcodegen.zip \
  --output "$commandkit_tools/xcodegen.zip"
printf '%s  %s\n' '090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef' "$commandkit_tools/xcodegen.zip" | shasum -a 256 --check
curl --fail --location --silent --show-error \
  https://github.com/realm/SwiftLint/releases/download/0.65.0/portable_swiftlint.zip \
  --output "$commandkit_tools/swiftlint.zip"
printf '%s  %s\n' 'd6cb0aa7a2f5f1ef306fc9e37bcb54dc9a26facc8f7784ac0c3dd3eccf5c6ba6' "$commandkit_tools/swiftlint.zip" | shasum -a 256 --check
unzip -qo "$commandkit_tools/xcodegen.zip" -d "$commandkit_tools/xcodegen"
unzip -qo "$commandkit_tools/swiftlint.zip" -d "$commandkit_tools/swiftlint"
commandkit_xcodegen="$commandkit_tools/xcodegen/xcodegen/bin/xcodegen"
commandkit_swiftlint="$commandkit_tools/swiftlint/swiftlint"
test "$("$commandkit_xcodegen" --version)" = 'Version: 2.45.4'
test "$("$commandkit_swiftlint" version)" = '0.65.0'
"$commandkit_xcodegen" --version
"$commandkit_swiftlint" version
if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$(dirname "$commandkit_xcodegen")" "$(dirname "$commandkit_swiftlint")" >> "$GITHUB_PATH"
fi
