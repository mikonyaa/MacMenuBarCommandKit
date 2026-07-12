# Getting Started

## Open the demo

```bash
open Examples/CommandKitDemo/CommandKitDemo.xcodeproj
```

Run the `CommandKitDemo` scheme on My Mac. The app opens a regular main window and installs a menu bar extra named CommandKit.

## Run from Terminal

```bash
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

The script builds the macOS target, kills any running `CommandKitDemo` process, launches the fresh app, and can stream logs or verify the process.

## Use as a template

1. Rename the demo app and bundle identifier.
2. Define app-owned `CommandID` constants and command metadata.
3. Initialize `DashboardStore` with your product activities and metrics.
4. Register command handlers in the app entry point.
5. Review Launch at Login behavior in a signed app bundle before shipping.

The demo fixtures are under `Examples/CommandKitDemo`; the package does not install sample commands or side effects by default.
