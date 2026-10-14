#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 || "$1" != /* ]]; then echo "usage: $0 <absolute-output-directory>" >&2; exit 2; fi
commandkit_capture_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$commandkit_capture_root"
# A commit identifies the captured implementation. Docs/assets may change later.
[[ -z "$(git status --porcelain --untracked-files=all -- Sources Package.swift \
  Examples/CommandKitDemo/CommandKitDemo/App Examples/CommandKitDemo/project.yml \
  Examples/CommandKitDemo/CommandKitDemo.xcodeproj/project.pbxproj)" ]] || {
  echo "Commit implementation source before capturing provenance" >&2; exit 2;
}
commandkit_capture_commit="$(git rev-parse HEAD)"
commandkit_output="$1"
commandkit_capture_build="$(mktemp -d "${TMPDIR:-/tmp}/commandkit-capture.XXXXXX")"
commandkit_capture_build="$(cd "$commandkit_capture_build" && pwd -P)"
commandkit_capture_bundle="$commandkit_capture_build/DerivedData/Build/Products/Debug/CommandKitDemo.app"
commandkit_capture_executable="$commandkit_capture_bundle/Contents/MacOS/CommandKitDemo"
commandkit_capture_pid=""
commandkit_capture_suite="CommandKitTests.Verify.Capture.$(uuidgen)"
echo "Owned native capture build: $commandkit_capture_build" >&2
cleanup_capture() {
  if [[ -n "$commandkit_capture_pid" ]]; then
    xcrun swift "$commandkit_capture_root/Tools/owned_app.swift" stop "$commandkit_capture_pid" \
      "$commandkit_capture_bundle" "$commandkit_capture_executable" "$commandkit_capture_suite" || true
  fi
}
trap cleanup_capture EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo \
  -destination 'platform=macOS' -derivedDataPath "$commandkit_capture_build/DerivedData" \
  COMMANDKIT_BUNDLE_ID="dev.liquidglasstemplates.commandkit.capture.$(date +%s)" \
  CODE_SIGNING_ALLOWED=NO build >"$commandkit_capture_build/build.log" 2>&1
mkdir -p "$commandkit_output"
for commandkit_surface in main-window menu-dashboard command-palette settings; do
  xcrun swift Tools/owned_app.swift launch "$commandkit_capture_bundle" "$commandkit_capture_build/pid" \
    --test-suite "$commandkit_capture_suite" --capture-directory "$commandkit_output" \
    --capture-surface "$commandkit_surface" --capture-commit "$commandkit_capture_commit"
  commandkit_capture_pid="$(cat "$commandkit_capture_build/pid")"
  for commandkit_attempt in {1..75}; do
    [[ -s "$commandkit_output/$commandkit_surface.json" ]] && break
    sleep 0.2
  done
  test -s "$commandkit_output/$commandkit_surface.png"
  test -s "$commandkit_output/$commandkit_surface.json"
  cleanup_capture
  commandkit_capture_pid=""
done
echo "Native content captures: $commandkit_output; source $commandkit_capture_commit; build $commandkit_capture_build"
