# Native acceptance and result form

Use an owned checkout, DerivedData, test bundle ID, defaults suite, and pasteboard. Never terminate another app by name or change unrelated login items. Baseline `0.2.0` is `ab43ae5d750f1005ee3e704b3756f4af8c2b3a37`.

## Automated fixtures

```bash
swift --version
xcodebuild -version
swift test
swiftlint version
swiftlint lint --strict
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' -derivedDataPath /absolute/owned/DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' -derivedDataPath /absolute/owned/DerivedData -resultBundlePath /absolute/owned/DemoModels.xcresult -only-testing:CommandKitDemoTests COMMANDKIT_BUNDLE_ID=dev.example.commandkit.ownedtest CODE_SIGNING_ALLOWED=NO test
python3 Tools/test_run_script.py --native
python3 Tools/test_app_relaunch.py --bundle /absolute/owned/DerivedData/Build/Products/Debug/CommandKitDemo.app
```

For the full test scheme (including XCUI), use an authenticated interactive Mac session:

```bash
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' -derivedDataPath /absolute/owned/DerivedData -resultBundlePath /absolute/owned/AllTests.xcresult COMMANDKIT_BUNDLE_ID=dev.example.commandkit.ownedtest CODE_SIGNING_ALLOWED=NO test
```

The RC workstation's XCUI runner returned `Authentication cancelled / System authentication is running`. Its native hosted consumer tests are separate evidence, not a substitute for the full XCUI journey. A hosted focus test explicitly skips when it cannot acquire a key window.

Create external consumers outside the checkout:

```bash
python3 Tools/prepare_consumer.py --baseline --output /absolute/empty/baseline-consumer
# In that directory: swift package resolve; swift build
python3 Tools/prepare_consumer.py --local "$PWD" --output /absolute/empty/rc-consumer
# In that directory: swift package resolve; swift build; swift test
# Optional: CONSUMER_CAPTURE_DIR=/absolute/owned/captures swift test
```

The baseline regression tests are expected to fail; installation/build must still succeed. Both fixtures import the product without `@testable` and define their own IDs. ConsumerHost is a runnable SwiftUI adoption fixture with 100 commands. Its hosted tests exercise public observation, native AppKit key events, rendered visibility with Vision OCR, selection, and menu availability. These are controlled native fixtures, not a developer pilot or an OS-level XCUI run.

## Interactive scenarios

| Scenario | Procedure | Expected outcome |
| --- | --- | --- |
| Catalog | While palette is open, replace 1→30→0→reload; reorder and remove selected ID through public API | Rows/metadata change without query mutation; valid selection stays; removed selection repairs; no stale handler call |
| Keyboard | Navigate 100 rows with Down, including held key; Return; narrow/no-match; hover then keys; Escape | Selection visible; exactly one correct action; no-match Return does nothing; keyboard remains in palette; previous control regains focus |
| Modal accessibility | With palette open, Tab/Shift-Tab, VoiceOver rotor and mouse on background | Background controls cannot run or be reached through AX; Escape closes without action |
| Outcomes | Success, explicit rejection, thrown error, missing handler, unknown ID, pasteboard false | Success uses success icon; failures show text/icon and AX failure outcome; attempts do not claim mutation |
| Preferences | In isolated suite, switch samples off, quit, launch again; change theme/presentation | No samples after relaunch; real entries survive toggle during session; theme/presentation round-trip |
| Inbox | Empty/whitespace Save, Cancel, multiline Save, read/copy/delete, 16 KiB boundary, 50 entries, Clear/Undo | Limits reject without mutation; unique IDs; Cancel adds none; copy readback matches; lifetime and deletion are explained |
| Timer | Launch with `--test-suite CommandKitTests.Manual.<UUID> --test-timer-seconds 2`; start/finish; repeat start; start/cancel; background and return after deadline | Running/remaining/finished/cancelled are visible; completed duration grows only on finish; no duplicate scheduler after view recreation |
| Sleep | Owned timer running; sleep and wake the Mac during an agreed test window | Deadline reconciliation finishes once; ticks are not accumulated as duration |
| Menu | Loaded/empty/error/loading; search none; Show all; close main window; Open Window, Settings, Quit | Independent commands remain available; all matches reachable; main returns; separate Settings opens; only own app quits |
| Accessibility | VoiceOver announces selected command/outcome; test Reduce Motion/Transparency, high contrast and long strings | Selected/outcome semantics audible; readable controls; motion preference honored; no clipped essential actions |

The `--empty`, `--error`, `--loading`, and `--show-palette` flags are presentation fixtures. Short timer, private pasteboard, fake login statuses, and capture flags require a `CommandKitTests.` suite. Use your own private pasteboard name `<suite>.clipboard`; tests never read or write the general pasteboard. Session inbox entries intentionally disappear on relaunch.

## Complete visual capture gate

Run `Scripts/capture_rc.sh /absolute/owned/captures` with an authenticated GUI session and existing screen-capture access. Select only this app's windows. Inspect sidebar, buttons, tabs, text and native chrome before calling the capture complete. A successful content bitmap write alone is insufficient. This RC's WindowServer attempt returned exit 1; fallback PNG/GIF provenance explicitly says partial. No privacy settings were changed. Replace the collection/profile hero only after full captures have passed visual review.

## Signed Launch at Login gate

1. Prepare a **separate stable bundle ID and installation path** for this test; sign with your own identity. Record `codesign -dv --verbose=4 /absolute/owned/CommandKitDemo.app`, macOS version, build/source SHA, and installation path.
2. Record initial SMAppService status. Enable only this app's login item. Observe enabled or requiresApproval; open Login Items through the app's approval action.
3. Approve only the owned item in System Settings. Return with Settings still open: status must refresh from SMAppService. Disable it externally and return again: UI must reflect disabled.
4. Exercise a registration error in a disposable signed fixture if feasible; retain detail and retry evidence. Fake tests do not satisfy this step.
5. Restore the owned item's initial registration state. Do not alter another login item. Any login/logout test requires an agreed session window; it was not performed automatically for this RC.

## Performance

No leak or speedup is inferred from source or a release checklist. Only investigate if the 100/1000-command fixture or a long session reveals a concrete problem. Record hardware/OS/build SHA, exact catalog/query, baseline, elapsed measurement, Instruments trace, view updates and retention. No cache is introduced for an unmeasured concern.

## Record actual results

Copy this form for each gate; leave unrun gates pending:

```text
Scenario:
Status: pass | fail | pending | skipped
Source SHA / bundle SHA:
OS / hardware / Xcode / Swift:
Owned suite / pasteboard / bundle ID / process IDs:
Exact commands and exit codes:
Actual steps and visible/AX outcomes:
Evidence paths / xcresult / screenshots / trace:
Cleanup and preserved resources:
Limitation or blocker:
Tester / timestamp:
```
