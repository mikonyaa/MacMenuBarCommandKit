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
            subtitle: "Capture a short AI-ready note.",
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
            id: "summarize-clipboard",
            title: "Summarize Clipboard",
            subtitle: "Turn copied text into a concise brief.",
            systemImage: "doc.on.clipboard",
            category: .ai,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "S"),
            action: .summarizeClipboard
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
