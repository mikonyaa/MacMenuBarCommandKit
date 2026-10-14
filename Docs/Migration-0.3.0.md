# Migration: 0.2.0 → 0.3.0 RC

The candidate uses the bare SemVer tag `0.3.0-rc.1`. This is an additive minor release candidate in a pre-1.0 package. macOS 14, Swift tools 6.0, product/module name, synchronous throwing handlers, and zero runtime dependencies are unchanged.

All existing public initializers remain callable. String-backed Codable/Sendable `CommandID`, command metadata/shortcut values, `CommandExecutionResult`, and MainActor ownership are retained. There is no new asynchronous handler protocol.

## Observation and selection

A view can observe only `CommandStore`. `registry.replaceCommands` invalidates it without changing query or copying the catalog. The bridge is cancelled with the store. A valid palette ID survives reorder; removal and query narrowing repair it. Palette selection is internal store state shared across view transitions.

`perform(oldCommandItem)` now resolves current metadata by ID. If that ID has been removed, the result is failure and its retained handler is not called. This deliberately fixes stale execution; callers that intentionally execute detached metadata must keep it registered or own that separate action themselves.

## Results

`latestResult: CommandExecutionResult?` preserves success/failure. The existing published `lastActionSummary` and `updateLastActionSummary` remain source compatible. A legacy summary is informational: it clears `latestResult` and receives a neutral icon. Use `updateLastActionResult(.failure(...))` or `.success(...)` for a completed editor or other app-owned follow-up.

`recentCommands` is a bounded, deduplicated list of requested known commands, including failures. It is not an audit trail and does not prove data mutation. Unknown IDs appear in `latestResult`; an app can retain its own richer attempt history. Demo history has UUIDs, timestamps, typed outcomes, and a 30-record limit (requests and labelled clock events).

## Preferences and login recovery

`SettingsStore(defaults:)` keeps its existing key names. The added `keyPrefix:` defaults to `MacMenuBarCommandKit.`. Initialize your app state after reading settings. The demo removes labelled sample entries when disabled; real session entries, attempts, and timer progress remain.

The existing Settings initializer with `LaunchAtLoginService` remains. The added initializer accepting `launchController:` lets apps and tests inject `LaunchAtLoginControlling`. Its added `openLoginItemsSettings()` requirement has a default implementation, so existing conformers compile. Fakes should override it to avoid opening system UI. Production status still comes from SMAppService; no independent enabled preference is persisted.

## Demo behavior

New Note opens an editor. Only a valid Save adds an entry; Cancel adds none. Capture Clipboard is an explicit read, and copy failures are shown. The inbox is **session only**: quit or Clear removes text; it is not an archive or persistent store. The maximum is 50 entries including samples and 16,384 UTF-8 bytes per entry. Clear can be undone until the next inbox change, including sample toggles.

Start Timer creates a 25-minute deadline. A repeated Start while running fails without restarting it. Cancel adds no completed duration; completion is reconciled from the clock, foreground, or wake, not accumulated ticks. The added Cancel Timer command uses `⌘⌥T`. Toggle Dashboard Focus changes only the dashboard badge and does not control system Focus/Do Not Disturb.

## Scrolling and tooling

The palette, dashboard, and menu use native ScrollView. Public `GrabScrollView` remains available for source compatibility; no leak or performance improvement is claimed. Keyboard scrolling is immediate; overlay transitions respect Reduce Motion.

`build_and_run.sh` no longer kills apps by name. It builds in an owned directory, launches a new instance through LaunchServices, verifies returned PID and bundle/executable paths, and stops only that instance. `run` waits until Quit or Ctrl-C. `--verify` uses an owned preferences suite and pasteboard, checks an actual status-report write/readback, then cleans up its own instance.

Read [RC validation](Validation-0.3.0-rc.1.md) and [native acceptance](NativeAcceptance.md) before treating the candidate as a final release.
