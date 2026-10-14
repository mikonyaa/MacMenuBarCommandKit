import AppKit
import MacMenuBarCommandKit
import SwiftUI

extension CommandID {
    static let newNote: CommandID = "note.new"
    static let startTimer: CommandID = "focus.start-timer"
    static let cancelTimer: CommandID = "focus.cancel-timer"
    static let captureClipboard: CommandID = "clipboard.capture"
    static let copyStatusReport: CommandID = "status.copy-report"
    static let clearInbox: CommandID = "inbox.clear"
    static let openDashboard: CommandID = "navigation.dashboard"
    static let toggleFocusMode: CommandID = "focus.toggle"
    static let openSettings: CommandID = "navigation.settings"
}

extension CommandItem {
    static let demoCommands: [CommandItem] = [
        CommandItem(
            id: .newNote,
            title: "New Note",
            subtitle: "Open an editor; Save adds a session note.",
            systemImage: "square.and.pencil",
            category: .productivity,
            shortcut: CommandShortcut(key: "N")
        ),
        CommandItem(
            id: .startTimer,
            title: "Start Timer",
            subtitle: "Begin a 25-minute focus block.",
            systemImage: "timer",
            category: .focus,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "T")
        ),
        CommandItem(
            id: .cancelTimer,
            title: "Cancel Timer",
            subtitle: "Cancel the running timer without adding completed time.",
            systemImage: "stop.circle",
            category: .focus,
            shortcut: CommandShortcut(modifiers: [.command, .option], key: "T")
        ),
        CommandItem(
            id: .captureClipboard,
            title: "Capture Clipboard",
            subtitle: "Read copied text into the session inbox.",
            systemImage: "doc.on.clipboard",
            category: .clipboard,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "V")
        ),
        CommandItem(
            id: .copyStatusReport,
            title: "Copy Status Report",
            subtitle: "Put a local progress report on the clipboard.",
            systemImage: "doc.text.magnifyingglass",
            category: .system,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "C")
        ),
        CommandItem(
            id: .clearInbox,
            title: "Clear Inbox",
            subtitle: "Delete all session entries; Undo Clear is available.",
            systemImage: "tray.and.arrow.down",
            category: .productivity,
            shortcut: CommandShortcut(modifiers: [.command, .shift], key: "X")
        ),
        CommandItem(
            id: .openDashboard,
            title: "Open Dashboard",
            subtitle: "Show the full command workspace.",
            systemImage: "rectangle.3.group",
            category: .navigation,
            shortcut: CommandShortcut(key: "D")
        ),
        CommandItem(
            id: .toggleFocusMode,
            title: "Toggle Dashboard Focus",
            subtitle: "Toggle the dashboard badge. System Focus is unchanged.",
            systemImage: "moon.circle",
            category: .focus,
            shortcut: CommandShortcut(modifiers: [.command, .option], key: "F")
        ),
        CommandItem(
            id: .openSettings,
            title: "Open Settings",
            subtitle: "Configure menu bar, launch, and demo data.",
            systemImage: "gearshape",
            category: .system,
            shortcut: CommandShortcut(key: ",")
        )
    ]
}

private extension CommandModifier {
    var eventModifier: EventModifiers {
        switch self {
        case .command: .command
        case .option: .option
        case .shift: .shift
        case .control: .control
        }
    }
}

extension CommandShortcut {
    var keyEquivalent: KeyEquivalent? {
        key.lowercased().first.map { KeyEquivalent($0) }
    }

    var eventModifiers: EventModifiers {
        modifiers.reduce(into: EventModifiers()) { result, modifier in
            result.insert(modifier.eventModifier)
        }
    }
}

extension View {
    @ViewBuilder
    func demoKeyboardShortcut(_ shortcut: CommandShortcut?) -> some View {
        if let shortcut, let key = shortcut.keyEquivalent {
            keyboardShortcut(key, modifiers: shortcut.eventModifiers)
        } else {
            self
        }
    }
}
