# 0.3.0-rc.1 release notes

This candidate fixes dynamic command observation and stale metadata execution, keeps execution severity through the UI, and replaces simulated demo actions with a bounded session inbox and a deadline timer.

- A public consumer can observe only CommandStore during catalog replacement; selection survives reorder and repairs removal/query changes.
- Palette rows have IDs and selected accessibility traits. Native field-editor routing handles arrows, Return, and Escape; keyboard selection scrolls into view. Background content is disabled and hidden from accessibility while the palette is open.
- `latestResult` preserves success/failure, with source-compatible summary access. Missing, thrown, explicit, and unknown-ID failures stay failures. Legacy informational summaries receive a neutral icon.
- Notes use a Save/Cancel editor. Inbox entries can be read, copied, and deleted; UTF-8/count limits are enforced. Clear has one session undo snapshot. Sample toggles preserve real entries.
- The 25-minute timer has idle/running/finished/cancelled states, repeat-start rejection, remaining time, foreground/wake reconciliation, and completed duration counted at completion. It does not alter system Focus.
- Commands remain rendered in loaded/empty/error/loading menu states. No-results and Show all controls explain the catalog. Window and Settings actions use an installed scene environment.
- Launch at Login shows error details and approval/retry actions, refreshes on foreground, and supports a fake controller without system registration.
- Owned launch tooling, independent consumers, demo model/UI test targets, bare SemVer CI tags, hash-verified tool downloads, and capture provenance are included.

Compatibility: additive minor RC; deployment target remains macOS 14 and tools version remains Swift 6.0. Existing initializers and summary publishers remain. See [migration](Migration-0.3.0.md) for intentional behavior corrections.

This is **not a 10/10 or production-ready assertion**. The [validation record](Validation-0.3.0-rc.1.md) separates observed checks from GUI, signed-login, accessibility, and minimum-runtime gates. WindowServer capture was denied; current PNGs/GIF have explicit partial native-layer coverage. Stale Notifications assets were removed. The GIF assembles captured PNGs and does not record interaction. No independent developer pilot or Instruments performance study is claimed.
