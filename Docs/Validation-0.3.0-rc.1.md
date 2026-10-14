# 0.3.0-rc.1 validation record

This is a reviewable release candidate. It does not assert 10/10 or production readiness. Dates below are observed workstation results on 2026-10-14; CI/public-source verification is recorded with the exact release's linked runs/assets when published.

Baseline main and `0.2.0`: **ab43ae5d750f1005ee3e704b3756f4af8c2b3a37**. Previous `0.1.0`: **8f8e7da3e7498c863e4d88ed2b95e5f5e20f1522**. Remote HEAD/refs/releases matched the supplied baseline at intake. No applicable AGENTS.md was found in the isolated checkout/ancestors. Existing working data and other sessions were not reset or terminated.

Implementation checkpoint: **a452c74db60bbdb1b42e906ecc3b8d2de5c41367**. Capture implementation checkpoint: **d8f49f6b6840b41ac641efbf74be41eebc9c36e3**. Subsequent candidate commits contain documentation/assets/check corrections. The full release commit is obtained from the exact bare tag `0.3.0-rc.1`; it is also recorded in release/public QA evidence. Capture SHA is distinct from the final documentation/assets commit.

## Actual workstation and tools

| Item | Observed version |
| --- | --- |
| Hardware | Apple M4, arm64 |
| macOS | 26.7.1, build 25G241 |
| Swift | 6.4; swiftlang-6.4.0.34.1; clang-2100.3.34.1 |
| Xcode | 27.0, build 27A266a; SDK macosx27.0 |
| XcodeGen | 2.45.4 |
| SwiftLint | 0.65.0 |
| Python/Pillow | Python 3.13 / Pillow 12.0.0 |

Package tools version remains 6.0, Swift language mode 6, deployment target macOS 14. Local SDK 27 compilation is not a runtime test on macOS 14 or a run with a Swift 6.0 compiler. CI explicitly selects compatibility Xcode 16.4/macOS-15 and current Xcode 26.5/macOS-26; its logs provide actual selected versions. Current is the matrix's name, not a claim that Xcode 26.5 is the newest installed workstation tool.

Tool downloads were executed and hash checked: XcodeGen 2.45.4 ZIP `090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef`; SwiftLint 0.65.0 portable ZIP `d6cb0aa7a2f5f1ef306fc9e37bcb54dc9a26facc8f7784ac0c3dd3eccf5c6ba6`. The linter matches the actual local strict run; pinning it prevents a Homebrew/latest drift between checks. Hashes were compared with the official release asset metadata and then the downloaded bytes.

## Concrete changes

| Path/symbol | Corrected contract |
| --- | --- |
| CommandStore.registryObservation / paletteSelection, CommandRegistry.filteredCommands(in:matching:) | One weak lifetime-bound forwarding subscription; one metadata owner; query/catalog repairs selection |
| CommandStore.perform / latestResult / updateLastActionResult | Current metadata by ID; removed/missing/thrown/explicit failures preserved; compatible summary publisher |
| CommandPalette / PaletteSearchField.Coordinator.control | Native field-editor key delivery, immediate scroll-to-selection, row IDs, one Return, Escape; guarded queued focus |
| CommandPaletteOverlay / AccessibilityAnnouncements / CommandRow | Background disabled/hit-test blocked/AX-hidden; selected traits and typed announcements; Reduce Motion respected |
| DemoInbox / DemoCommandRuntime / DemoRootView | Typed stable-ID entries, editor Save/Cancel, read/copy/delete, 50-entry/16 KiB UTF-8 limits, Clear/Undo, labelled samples |
| DemoTimer / DemoCommandRuntime.reconcileTimer | Clock/deadline states, repeat-start policy, cancellation, foreground/wake and one owned ticker; clock event is not a successful request |
| DemoLaunchConfiguration / CommandKitDemoApp.init | Read persisted preferences before fixtures; owned native app-launch suite/clipboard fixtures |
| DemoSceneActions / DemoCommandMenus / AppDelegate | Installed scene actions; independent Open Window; startup restores main and preserves other app instances |
| MenuBarDashboard | Commands rendered in all data states; visible no-match and Show all; typed failure header |
| LaunchAtLoginViewModel / CommandKitSettingsView | Injected controller, live service forwarding, error detail, approval action, retry and foreground truth |
| build_and_run.sh / owned_app.swift | Validate first, build first, LaunchServices-returned PID plus bundle/executable identity; only own cleanup |
| CI / project.yml / generated project / integration fixtures | Bare SemVer tags, logged/pinned tools, testables, separate consumer, reproducible project |

Source compatibility: existing public initializers, String-backed Codable/Sendable IDs, metadata/shortcut values, throwing synchronous handlers and macOS 14 minimum remain. Additions are typed latest result/update method, optional defaults prefix, controller-based Settings initializer and defaulted login-settings protocol method. Resolving an old CommandItem now rejects removed metadata intentionally; [migration](Migration-0.3.0.md) explains that behavior correction. SemVer category is additive minor **0.3.0 RC**, source-only SPM distribution.

## Commands and measured outcomes

| Check | Result/exit | Meaning |
| --- | --- | --- |
| Baseline root `swift test` | 0; 7 tests passed | New actual Mac baseline package evidence |
| RC root `swift test` | 0; 12 tests passed | Severity/legacy placeholder, prefix isolation, bridge lifetime, fake login model and rendered fake recovery/foreground, original contracts |
| `swiftlint lint --strict` | 0 | 0 warnings/errors with pinned 0.65.0 |
| Demo `xcodebuild … CODE_SIGNING_ALLOWED=NO build` | 0 | Real Apple SDK/macOS 14 deployment build |
| Demo `xcodebuild … -only-testing:CommandKitDemoTests … test` | 0; 9 tests passed | Editor model, limits/undo/IDs, explicit clipboard/failure/private pasteboard, persisted initial preferences, fake deadline/wake/foreground, live native ticker/weak lifetime |
| Full test scheme including XCUI | 65; UI runner authentication blocker | Model test pass does not imply UI journey pass; no authentication/security setting was changed |
| Baseline external exact `0.2.0` resolve/build | 0 / 0, repeated in a fresh directory/cache | Public installation and product import; own tools 6.0/macOS 14 package and IDs |
| Baseline `swift test --filter ObservationTests` | 1; 3 cases with 7 assertion failures | Reproduced missing observer/redraw and stale/removed metadata execution; expected regression result |
| Local RC external resolve/build/test | 0 / 0 / 0; 7 cases, 6 passed, 1 skipped | No @testable; hosted 1→30→0→reload, current metadata, real AppKit key events to row 100 with rendered OCR visibility/one action, reorder/removal/query/no-match/Escape, menu state rendering |
| Hosted native focus case | skipped | Process cannot acquire a key window; active-window restoration is pending, not green |
| `python3 Tools/test_run_script.py --native` | 0 | Invalid/extra args 2 before build; build failure 42; foreign same-name fixture survived; own bundle/PID/window/private write/readback checked; own PID stopped |
| `python3 Tools/test_app_relaunch.py --bundle …` | 0 | Two real app PIDs; second launch has no preference/seed flags; off/dark/compact and zero samples/inbox persist in initial app state |
| Shell/Python/YAML checks, `git diff --check` | 0 | Syntax/config/hygiene |
| XcodeGen 2.45.4 generate twice, then project `git diff --exit-code` | 0 | Committed generated project reproduces byte for byte |
| GIF assembler/decoder | 0; 4 frames, 1600×1000 | Assembles partial native PNGs; no interaction recording |

External consumer paths are outside the checkout, with fresh caches for the repeat. Native key events are controlled NSEvent delivery through actual AppKit/SwiftUI and rendered native pixels checked by Vision. Menu availability combines real view rendering/OCR with public independent handler execution; it is not proof of a physical system status-item click. The independent consumer is a prepared adoption fixture, not a developer pilot.

Raw local logs/xcresults are retained in the owned task directory, with selected machine-readable [local facts](Evidence/local-results.json). UserDefaults suites, pasteboards, PIDs and build paths were task-owned; the general pasteboard and existing login items/settings were not modified. Native build emitted Apple's `Metadata extraction skipped, no AppIntents.framework dependency found` warning; no new first-party source compiler warning is claimed hidden by the check.

## Capture provenance and remaining gates

[Capture provenance](Evidence/capture-provenance.json) records the source SHA, OS, mechanism, coverage and SHA-256 for each new PNG and GIF. WindowServer access preflight returned false; window-only capture returned exit 1. NSView.cacheDisplay captured actual RC content views but omitted some layer-backed/sidebar/native controls. Those files are labelled **partial** under `Assets/NativeCaptures/0.3.0-rc.1`; the menu is the actual MenuBarDashboard in a standalone native host. Old PNG/GIF with the stale Notifications toggle were removed. Partial artifacts are not approved as a full public collection hero.

Pending external conditions:

1. Authenticated full XCUI/physical keys, hover→keys, modal Tab/AX reachability, active-window focus restoration, actual status-item and window-closed menu/shortcut navigation.
2. Actual VoiceOver audible selection/outcome and interactive Reduce Motion/Transparency/high-contrast/long-text review. Code traits/announcements and a checklist do not close this gate.
3. Own signed stable bundle Launch at Login: system enabled/approval/error/return refresh and restoration of only the owned registration. Fake/render tests are separate.
4. Real agreed sleep/wake test and visible short native timer journey; fake sleep reconciliation and the live model ticker passed, but do not simulate actual machine sleep.
5. Complete visually reviewed WindowServer/app screenshots with existing permission; current native-layer captures remain partial.
6. Runtime on the minimum macOS 14 and exact minimum compiler where claimed. CI compatibility/current build results are tracked with their exact logs and do not imply that runtime check.

No Instruments/performance gain/retention leak or independent pilot is asserted. Investigate performance only after a concrete 100/1000-command or long-session issue. [Native acceptance](NativeAcceptance.md) supplies exact steps, expected outcomes, isolated test build and a factual result form for every pending gate. [Release notes](ReleaseNotes-0.3.0-rc.1.md) and [collection/profile proposal](CatalogProposal-0.3.0.md) keep those limits visible.
