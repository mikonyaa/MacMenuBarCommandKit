# Commands

Commands are defined by metadata and executed by handlers.

## Metadata

`CommandItem` includes:

- `id`
- `title`
- `subtitle`
- `systemImage`
- `category`
- `shortcut`
- `action`

The UI uses this metadata to render rows, search results, shortcuts, and menu bar actions.

## Search

`CommandRegistry.filteredCommands(matching:)` normalizes query text and requires every token to match the command's searchable text. Search covers title, subtitle, category, shortcut display value, and action id.

## Handlers

Register handlers where your app owns side effects:

```swift
registry.register(.newNote) { command in
    createNote(title: command.title)
}
```

Window and Settings actions are routed in the demo app because they use SwiftUI environment actions.

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

Avoid registering the same shortcut in multiple command menus.

## Demo command scope

The template ships with eight commands because a menu bar utility should stay quick to scan. The first commands are daily actions, while navigation and settings remain searchable from the palette and visible in the main window.
