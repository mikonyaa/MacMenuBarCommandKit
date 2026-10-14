#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; }
# Validate before creating paths, building, launching, or touching a process.
if [[ $# -gt 1 ]]; then usage; exit 2; fi
case "${1:-run}" in
  run) mode=run ;;
  --debug|debug) mode=debug ;;
  --logs|logs) mode=logs ;;
  --telemetry|telemetry) mode=telemetry ;;
  --verify|verify) mode=verify ;;
  *) usage; exit 2 ;;
esac

commandkit_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
commandkit_run_root="$(mktemp -d "${TMPDIR:-/tmp}/commandkit-run.XXXXXX")"
commandkit_run_root="$(cd "$commandkit_run_root" && pwd -P)"
commandkit_project="$commandkit_root/Examples/CommandKitDemo/CommandKitDemo.xcodeproj"
commandkit_bundle="$commandkit_run_root/DerivedData/Build/Products/Debug/CommandKitDemo.app"
commandkit_executable="$commandkit_bundle/Contents/MacOS/CommandKitDemo"
commandkit_checkout_id="$(printf '%s' "$commandkit_root" | shasum -a 256 | cut -c1-12)"
commandkit_bundle_id="dev.liquidglasstemplates.commandkit.local.$commandkit_checkout_id"
commandkit_suite="CommandKitTests.Verify.$(uuidgen)"
commandkit_pid=""

is_owned_process() {
  [[ -n "$commandkit_pid" ]] && kill -0 "$commandkit_pid" 2>/dev/null &&
    [[ "$(ps -p "$commandkit_pid" -o comm=)" == "$commandkit_executable" ]]
}
cleanup() {
  if is_owned_process; then
    xcrun swift "$commandkit_root/Tools/owned_app.swift" stop "$commandkit_pid" \
      "$commandkit_bundle" "$commandkit_executable" "$commandkit_suite" || true
  fi
  echo "Owned build and logs: $commandkit_run_root" >&2
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# A failed build leaves every existing application untouched.
if xcodebuild -project "$commandkit_project" -scheme CommandKitDemo \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath "$commandkit_run_root/DerivedData" \
  COMMANDKIT_BUNDLE_ID="$commandkit_bundle_id" CODE_SIGNING_ALLOWED=NO build \
  >"$commandkit_run_root/build.log" 2>&1; then
  echo "Built: $commandkit_bundle" >&2
else
  commandkit_build_exit=$?
  cat "$commandkit_run_root/build.log" >&2
  exit "$commandkit_build_exit"
fi

# LaunchServices delivers the normal app-open event and returns its own PID.
if [[ "$mode" == verify ]]; then
  xcrun swift "$commandkit_root/Tools/owned_app.swift" launch "$commandkit_bundle" "$commandkit_run_root/pid" \
    --test-suite "$commandkit_suite" --test-demo-data-off --verify-output "$commandkit_run_root/health.json"
else
  xcrun swift "$commandkit_root/Tools/owned_app.swift" launch "$commandkit_bundle" "$commandkit_run_root/pid"
fi
commandkit_pid="$(cat "$commandkit_run_root/pid")"
[[ "$commandkit_pid" =~ ^[0-9]+$ ]] || { echo "Invalid owned PID" >&2; exit 1; }

case "$mode" in
  debug)
    lldb -p "$commandkit_pid"
    ;;
  verify)
    for commandkit_attempt in {1..50}; do
      [[ -s "$commandkit_run_root/health.json" ]] && break
      kill -0 "$commandkit_pid" 2>/dev/null || break
      sleep 0.2
    done
    is_owned_process || { echo "Owned executable did not stay alive" >&2; exit 1; }
    python3 - "$commandkit_run_root/health.json" "$commandkit_pid" "$commandkit_bundle" "$commandkit_executable" <<'PY'
import json
import pathlib
import sys
health = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert health['pid'] == int(sys.argv[2]), health
assert pathlib.Path(health['bundlePath']).resolve() == pathlib.Path(sys.argv[3]).resolve(), health
assert pathlib.Path(health['executablePath']).resolve() == pathlib.Path(sys.argv[4]).resolve(), health
assert health['hasWindow'] and health['actionSucceeded'] and health['clipboardReadbackMatches'], health
print(json.dumps(health, sort_keys=True))
PY
    ;;
  logs|telemetry)
    /usr/bin/log stream --info --style compact --predicate "processID == $commandkit_pid"
    ;;
  run)
    echo "Running owned PID $commandkit_pid. Quit the app or press Ctrl-C to stop this instance." >&2
    while is_owned_process; do sleep 0.25; done
    ;;
esac
