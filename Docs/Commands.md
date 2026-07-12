# Commands

Commands are defined by metadata and executed by app-owned handlers.

## Metadata

`CommandItem` includes:

- `id`
- `title`
- `subtitle`
- `systemImage`
- `category`
- `shortcut`

The `id` is a string-backed `CommandID` owned by your app. The UI uses this metadata to render rows, search results, shortcuts, and menu bar actions.

## Search

`CommandRegistry.filteredCommands(matching:)` normalizes query text and requires every token to match the command's searchable text. Search covers title, subtitle, category, shortcut display value, and command ID.

## Handlers

Register handlers where your app owns side effects:

```swift
registry.register(.newNote) { command in
    try createNote(title: command.title)
    return .success("Created a local note.")
}
```

Handlers are synchronous and may throw. `CommandStore` converts returned values and thrown errors into a visible `CommandExecutionResult`; there is no speculative async command layer. Window, Settings, pasteboard, and sample state mutations stay in the demo app.

## Shortcuts

The demo exposes:

- `⌘K`: open command palette
- `⌘N`: New Note
- `⌘⇧T`: Start Timer
- `⌘⇧V`: Capture Clipboard
- `⌘⇧C`: Copy Status Report
- `⌘⇧X`: Clear Inbox
- `⌘,`: Settings
- `⌘D`: Open Dashboard
- `⌘⌥F`: Toggle Focus Mode

The demo reads each command shortcut from `CommandItem` when building menus and the Settings summary. Avoid copying shortcut literals into another source of truth.

The palette supports Up/Down navigation, Return to execute, Escape to close, and restores the previous first responder when dismissed.

## Demo command scope

The eight sample commands, their IDs, fixtures, and default side effects live only under `Examples/CommandKitDemo`. The package registry starts empty.
