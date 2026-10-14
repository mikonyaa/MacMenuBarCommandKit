# Commands

Commands are metadata connected to app-owned synchronous throwing handlers on MainActor. `CommandID` is string-backed, Codable and Sendable; define unique IDs in your app. `CommandItem` carries title/subtitle, symbol, category and optional metadata-driven `CommandShortcut`.

```swift
let id: CommandID = "myapp.export.summary"
registry.register(id) { current in
    try exportSummary()
    return .success("Exported \(current.title).")
}
```

The registry begins empty. `filteredCommands(matching:)` folds case/diacritics and requires all tokens to match title, subtitle, category, shortcut display or ID. `replaceCommands` immediately invalidates a CommandStore observer; no query mutation or duplicated catalog is required.

`store.perform(id)` and `store.perform(item)` resolve current metadata by ID. Removed/unknown IDs, missing handlers, thrown errors and explicit rejection become failures. No default handler runs. Handler closures remain synchronous: New Note reports that its editor opened; app-owned Save later publishes its own result with `updateLastActionResult`.

`latestResult` keeps severity. Published `lastActionSummary` and its setter remain compatible; a legacy summary is informational and clears the typed result. `recentCommands` includes failed known requests and is not proof of mutation. Rich records/IDs/timestamps belong to the app. Demo history is bounded to 30 requests/timer events, with samples separately labelled.

## Palette and menu

The palette uses native ScrollViewReader actions at onChange boundaries, row IDs, immediate scroll-to-selection, selected AX traits and native field-editor delegates. Up/Down selects, Return dispatches once, no-match Return does nothing, Escape closes. Valid IDs survive reorder; removed IDs/query narrowing repair selection. Background content is disabled and AX-hidden while presented. Outcome and keyboard selection announcements are posted when VoiceOver is enabled. [Native acceptance](NativeAcceptance.md) separately verifies audible results, modal reachability, active-window focus and physical key delivery.

The menu renders independent commands in all dashboard states, explains no-match/empty catalogs and provides Show all when more than four match. Window/Settings/Quit footer actions are independent of data.

## Demo shortcuts

| Shortcut | Action |
| --- | --- |
| ⌘K | Palette |
| ⌘N | Note editor |
| ⌘⇧T / ⌘⌥T | Start / Cancel Timer |
| ⌘⇧V | Capture Clipboard |
| ⌘⇧C | Copy Status Report |
| ⌘⇧X | Clear Inbox |
| ⌘D / ⌘, | Dashboard / Settings |
| ⌘⌥F | Toggle Dashboard Focus badge |

Nine demo commands and their IDs/handlers live in Examples. Real clipboard reads occur only on Capture; tests use named pasteboards or fakes. Inbox entries are readable/copyable/deletable, at most 50 including samples and 16,384 UTF-8 bytes each, session only. Clear is deletion with one undo snapshot. The 25-minute timer derives remaining/completion from the deadline and does not change system Focus.
