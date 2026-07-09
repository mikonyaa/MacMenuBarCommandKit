import Foundation

public struct CommandItem: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var systemImage: String
    public var category: CommandCategory
    public var shortcut: CommandShortcut?
    public var action: CommandAction

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        category: CommandCategory,
        shortcut: CommandShortcut? = nil,
        action: CommandAction
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.category = category
        self.shortcut = shortcut
        self.action = action
    }

    public var searchableText: String {
        [
            title,
            subtitle,
            category.title,
            shortcut?.displayValue ?? "",
            action.rawValue
        ]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }
}

public extension CommandItem {
    static let demoCommands: [CommandItem] = [
        CommandItem(
            id: "new-note",
            title: "New Note",
            subtitle: "Capture a short local note.",
            systemImage: "square.and.pencil",
            category: .productivity,
            shortcut: CommandShortcut(key: "N"),
            action: .newNote
        ),
        CommandItem(
            id: "start-timer",
            title: "Start Timer",
            subtitle: "Begin a 25-minute focus block.",
            systemImage: "timer",
            category: .focus,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "T"),
            action: .startTimer
        ),
        CommandItem(
            id: "capture-clipboard",
            title: "Capture Clipboard",
            subtitle: "Save copied text to the local inbox.",
            systemImage: "doc.on.clipboard",
            category: .clipboard,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "V"),
            action: .captureClipboard
        ),
        CommandItem(
            id: "copy-status-report",
            title: "Copy Status Report",
            subtitle: "Put a local progress report on the clipboard.",
            systemImage: "doc.text.magnifyingglass",
            category: .system,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "C"),
            action: .copyStatusReport
        ),
        CommandItem(
            id: "clear-inbox",
            title: "Clear Inbox",
            subtitle: "Archive waiting local items in one action.",
            systemImage: "tray.and.arrow.down",
            category: .productivity,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "X"),
            action: .clearInbox
        ),
        CommandItem(
            id: "open-dashboard",
            title: "Open Dashboard",
            subtitle: "Show the full command workspace.",
            systemImage: "rectangle.3.group",
            category: .navigation,
            shortcut: CommandShortcut(key: "D"),
            action: .openDashboard
        ),
        CommandItem(
            id: "toggle-focus-mode",
            title: "Toggle Focus Mode",
            subtitle: "Quiet the dashboard and highlight active work.",
            systemImage: "moon.circle",
            category: .focus,
            shortcut: CommandShortcut(modifiers: [.command, .option], key: "F"),
            action: .toggleFocusMode
        ),
        CommandItem(
            id: "open-settings",
            title: "Open Settings",
            subtitle: "Configure menu bar, launch, and demo data.",
            systemImage: "gearshape",
            category: .system,
            shortcut: CommandShortcut(key: ","),
            action: .openSettings
        )
    ]
}
