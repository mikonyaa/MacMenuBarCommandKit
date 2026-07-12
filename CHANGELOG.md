# Changelog

## 0.2.0

- Replaced the closed `CommandAction` enum with app-owned, string-backed `CommandID` values.
- Added synchronous throwing handlers with explicit success and failure results.
- Moved demo IDs, fixtures, clipboard persistence, and sample side effects out of the package.
- Added arrow navigation, Return, Escape, and focus restoration to the command palette.
- Made command metadata the shortcut source for menus and Settings.
- Reconciled Launch at Login directly with `SMAppService` status and removed the inactive notification placeholder.
- Added a `0.1.0` to `0.2.0` migration guide.

## 0.1.0

- Initial release of MacMenuBarCommandKit.
- Added reusable command models, stores, SwiftUI views, and Launch at Login service.
- Added runnable macOS demo app with menu bar dashboard, main window, command palette, Settings, and keyboard shortcuts.
- Added unit tests, documentation, preview assets, CI, and GitHub community files.
