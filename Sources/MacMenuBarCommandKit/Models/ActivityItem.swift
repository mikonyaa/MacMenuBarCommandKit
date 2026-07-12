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

    public static func commandActivity(
        for command: CommandItem,
        summary: String,
        tone: ActivityTone = .neutral
    ) -> ActivityItem {
        ActivityItem(
            id: "\(command.id.rawValue)-\(UUID().uuidString)",
            title: command.title,
            subtitle: summary,
            systemImage: command.systemImage,
            timestamp: "Just now",
            tone: tone
        )
    }
}
