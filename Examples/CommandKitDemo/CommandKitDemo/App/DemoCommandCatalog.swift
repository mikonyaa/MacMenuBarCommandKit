import AppKit
import MacMenuBarCommandKit
import SwiftUI

extension CommandID {
    static let newNote: CommandID = "note.new"
    static let startTimer: CommandID = "focus.start-timer"
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
            subtitle: "Capture a short local note.",
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
            id: .captureClipboard,
            title: "Capture Clipboard",
            subtitle: "Save copied text to the local inbox.",
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
            subtitle: "Archive waiting local items in one action.",
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
            title: "Toggle Focus Mode",
            subtitle: "Quiet the dashboard and highlight active work.",
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

extension ActivityItem {
    static let demo: [ActivityItem] = [
        ActivityItem(
            id: "clip-captured",
            title: "Clipboard captured",
            subtitle: "Copied text saved to the local inbox.",
            systemImage: "doc.on.clipboard",
            timestamp: "2 min ago",
            tone: .accent
        ),
        ActivityItem(
            id: "focus-started",
            title: "Focus timer started",
            subtitle: "Deep work block ends at 15:25.",
            systemImage: "timer",
            timestamp: "8 min ago",
            tone: .success
        ),
        ActivityItem(
            id: "draft-note",
            title: "New note captured",
            subtitle: "Saved to the local command inbox.",
            systemImage: "note.text",
            timestamp: "21 min ago",
            tone: .neutral
        )
    ]
}

@MainActor
final class DemoCommandRuntime: ObservableObject {
    @Published private(set) var clipboardEntries: [String] = []
    @Published private(set) var notes: [String] = []
    private(set) var commandRunCount = 42
    private(set) var focusMinutes = 150
    private(set) var inboxItems = 7
    private(set) var focusActive = false

    var metrics: [MetricCard] {
        [
            MetricCard(
                id: "commands",
                title: "Commands",
                value: "\(commandRunCount)",
                caption: "run today",
                systemImage: "command",
                trend: .up
            ),
            MetricCard(
                id: "focus",
                title: "Focus",
                value: focusActive ? "Active" : String(format: "%.1fh", Double(focusMinutes) / 60),
                caption: focusActive ? "timer running" : "protected",
                systemImage: "moon.circle",
                trend: focusActive ? .up : .flat
            ),
            MetricCard(
                id: "queue",
                title: "Inbox",
                value: "\(inboxItems)",
                caption: "items waiting",
                systemImage: "tray.full",
                trend: inboxItems == 0 ? .flat : .down
            )
        ]
    }

    func recordSuccessfulRun() {
        commandRunCount += 1
    }

    func createNote() -> String {
        let note = "Untitled note \(notes.count + 1)"
        notes.insert(note, at: 0)
        inboxItems += 1
        return "Saved \(note.lowercased()) to the local inbox."
    }

    func startTimer() -> String {
        focusMinutes += 25
        focusActive = true
        return "Started a 25-minute focus timer."
    }

    func captureClipboard() throws -> String {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DemoCommandError.emptyClipboard
        }

        clipboardEntries.insert(trimmed, at: 0)
        inboxItems += 1
        return "Saved \(trimmed.count) clipboard characters to the local inbox."
    }

    func clearInbox() -> String {
        clipboardEntries.removeAll()
        notes.removeAll()
        inboxItems = 0
        return "Cleared notes and captured clipboard content."
    }

    func toggleFocus() -> String {
        focusActive.toggle()
        return focusActive ? "Focus mode enabled." : "Focus mode disabled."
    }

    func copyStatusReport(recentCommandCount: Int) -> String {
        let report = """
        CommandKit Status
        Commands: \(commandRunCount)
        Recent: \(recentCommandCount)
        Focus: \(focusActive ? "active" : "ready")
        Clipboard items: \(clipboardEntries.count)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        return "Copied status report to the clipboard."
    }

    func tone(for id: CommandID, result: CommandExecutionResult) -> ActivityTone {
        guard result.succeeded else { return .warning }
        switch id {
        case .startTimer, .toggleFocusMode:
            return .success
        case .clearInbox:
            return .warning
        case .openDashboard, .openSettings:
            return .neutral
        default:
            return .accent
        }
    }
}

enum DemoCommandError: LocalizedError {
    case emptyClipboard

    var errorDescription: String? {
        "The clipboard is empty. Copy text and run the command again."
    }
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
