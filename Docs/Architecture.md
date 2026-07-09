# Architecture

MacMenuBarCommandKit separates reusable command UI from app-owned platform behavior.

## Layers

- `Models`: stable value types such as `CommandItem`, `ActivityItem`, `MetricCard`, and `AppSettings`.
- `Stores`: observable state owners for commands, dashboard state, and persisted settings.
- `Services`: platform wrappers such as `LaunchAtLoginService`.
- `Views`: SwiftUI surfaces for menu bar, dashboard, command palette, settings, and shared components.
- `Examples/CommandKitDemo`: app entry point, scene wiring, command routing, and Xcode project.

## Command flow

`CommandRegistry` owns command metadata and optional handlers. `CommandStore` owns search query, palette presentation, recent commands, focus mode, and action summaries. The demo app routes commands that need platform APIs, such as opening windows or Settings.

This keeps the package reusable: UI can render command metadata without knowing whether a command starts a timer, transforms clipboard text, or opens another window.

## Scene model

The demo uses:

- `WindowGroup("CommandKit", id: "main")` for the main Dock-visible app window.
- `MenuBarExtra(...).menuBarExtraStyle(.window)` for the compact dashboard.
- `Settings` for preferences.
- SwiftUI `commands` for keyboard-first desktop behavior.

The default app is Dock-visible because it is easier to debug and clearer for template users. No-Dock accessory mode is documented in `Customization.md`.
