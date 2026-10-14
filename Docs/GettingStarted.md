# Getting started

The package requires Swift tools 6.0 and macOS 14+. Apple SDKs and a Mac are required for native builds. Actual tested versions are recorded in [RC validation](Validation-0.3.0-rc.1.md); a deployment target is not a minimum-OS runtime test.

Open `Examples/CommandKitDemo/CommandKitDemo.xcodeproj`, choose CommandKitDemo / My Mac, and run. The checked-in project has model and UI test targets. Reproduce it with XcodeGen **2.45.4** from `Examples/CommandKitDemo`; generate twice and compare the second result to the committed reference.

```bash
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

Arguments are checked first. The script builds in owned DerivedData before launch; LaunchServices returns a new PID with the exact bundle/executable paths. `run` waits until Quit/Ctrl-C. Logs and debugger target only that instance. Verify checks an open main window and a status-report write/readback in a private pasteboard, then stops its own PID. It never terminates apps by a common name, and a failed build preserves existing instances.

## Adopt the package

```swift
.package(url: "https://github.com/mikonyaa/MacMenuBarCommandKit.git", exact: "0.3.0-rc.1")
.product(name: "MacMenuBarCommandKit", package: "MacMenuBarCommandKit")
```

For stable baseline installation use exact `0.2.0`. [Native acceptance](NativeAcceptance.md) contains the independent baseline/RC consumers. They use tools 6.0/macOS 14, their own IDs, and public imports without `@testable`.

Create models on MainActor. Define unique app-owned IDs and metadata, then register synchronous throwing handlers. Observe CommandStore alone; it forwards catalog replacement. UI execution resolves current metadata by ID. Consume typed `latestResult` for severity; summary-only legacy updates are neutral. Own timestamps/history/business state in your app.

Initialize SettingsStore before building sample app state. The demo uses stable-ID note/clipboard entries, an editor and a real deadline timer. Inbox data is session only (quit/Clear removes it); limits and undo are visible. Samples are labelled and removable without deleting real entries. Commands remain available independently of dashboard data state.

## Verify before shipping

Use the model/full UI commands and result form in [native acceptance](NativeAcceptance.md). GUI focus, VoiceOver, actual status-item activation, sleep, minimum-runtime testing and signed Launch at Login have explicit gates. Fake status tests or successful type checking are not that evidence.

For native PNGs run `Scripts/capture_rc.sh /absolute/owned/captures` after committing implementation source. Each capture records SHA/OS/mechanism/coverage. Full window capture requires existing screen-capture access; a denied capture is retained only as an explicit partial native-content fallback. The menu view uses a native capture host. `Scripts/record_showcase.sh` only assembles those PNGs into a GIF; it does not record the app.
