import Foundation

public enum ActivityTone: String, CaseIterable, Codable, Sendable {
    case accent
    case success
    case warning
    case neutral
}

public struct ActivityItem: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var systemImage: String
    public var timestamp: String
    public var tone: ActivityTone

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        timestamp: String,
        tone: ActivityTone
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.timestamp = timestamp
        self.tone = tone
    }

    public static let demo: [ActivityItem] = [
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

    public static func commandActivity(for command: CommandItem, summary: String) -> ActivityItem {
        ActivityItem(
            id: "\(command.id)-\(UUID().uuidString)",
            title: command.title,
            subtitle: summary,
            systemImage: command.systemImage,
            timestamp: "Just now",
            tone: tone(for: command.action)
        )
    }

    private static func tone(for action: CommandAction) -> ActivityTone {
        switch action {
        case .newNote, .captureClipboard, .copyStatusReport:
            .accent
        case .startTimer, .toggleFocusMode:
            .success
        case .clearInbox:
            .warning
        case .openDashboard, .openSettings:
            .neutral
        }
    }
}
