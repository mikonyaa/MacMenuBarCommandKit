# Changelog

## 0.3.0-rc.1

- Forward dynamic registry observation through CommandStore; preserve/repair selection and resolve current metadata at execution.
- Add typed latestResult and completed-action publication with compatible summary access and honest success/failure UI.
- Apply persisted preferences before fixtures; sample removal preserves real session data.
- Add bounded typed inbox, note editor, read/copy/delete/Clear/Undo, injected clipboard failure handling and UTF-8 limits.
- Replace simulated focus duration with a deadline timer, cancellation, repeat-start policy, foreground/wake reconciliation and owned native ticker.
- Route palette keys through the native field-editor delegate, scroll selected rows into view, and add selection/outcome accessibility semantics.
- Keep menu commands available across dashboard states; add no-results and overflow controls; install navigation actions from real scene environments.
- Add fake login recovery UI tests, error/approval/retry/foreground behavior and a separate signed-app acceptance procedure.
- Add independent public consumers, demo model/UI test targets, owned PID/bundle launch tooling and native relaunch fixtures.
- Pin/hash CI tooling, match bare SemVer tags and reproduce the generated Xcode project.
- Refresh native PNG/GIF provenance and document GUI/signed-login/minimum-runtime pending gates. RC is not a production-readiness claim.

## 0.2.0

- Replaced the closed `CommandAction` enum with app-owned, string-backed `CommandID` values.
- Added synchronous throwing handlers with explicit success and failure results.
- Moved demo IDs, fixtures, clipboard session state, and sample side effects out of the package.
- Added arrow navigation, Return, Escape, and focus restoration to the command palette.
- Made command metadata the shortcut source for menus and Settings.
- Reconciled Launch at Login directly with `SMAppService` status and removed the inactive notification placeholder.
- Added a `0.1.0` to `0.2.0` migration guide.

## 0.1.0

- Initial release of MacMenuBarCommandKit.
- Added reusable command models, stores, SwiftUI views, and Launch at Login service.
- Added runnable macOS demo app with menu bar dashboard, main window, command palette, Settings, and keyboard shortcuts.
- Added unit tests, documentation, preview assets, CI, and GitHub community files.
