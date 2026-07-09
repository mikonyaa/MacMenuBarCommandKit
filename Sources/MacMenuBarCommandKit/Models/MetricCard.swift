import Foundation

public enum MetricTrend: String, CaseIterable, Codable, Sendable {
    case up
    case down
    case flat

    public var systemImage: String {
        switch self {
        case .up:
            "arrow.up.right"
        case .down:
            "arrow.down.right"
        case .flat:
            "minus"
        }
    }
}

public struct MetricCard: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var title: String
    public var value: String
    public var caption: String
    public var systemImage: String
    public var trend: MetricTrend

    public init(
        id: String,
        title: String,
        value: String,
        caption: String,
        systemImage: String,
        trend: MetricTrend
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.caption = caption
        self.systemImage = systemImage
        self.trend = trend
    }

    public static let demo: [MetricCard] = [
        MetricCard(
            id: "commands",
            title: "Commands",
            value: "42",
            caption: "run today",
            systemImage: "command",
            trend: .up
        ),
        MetricCard(
            id: "focus",
            title: "Focus",
            value: "2.5h",
            caption: "protected",
            systemImage: "moon.circle",
            trend: .flat
        ),
        MetricCard(
            id: "queue",
            title: "Inbox",
            value: "7",
            caption: "items waiting",
            systemImage: "tray.full",
            trend: .down
        )
    ]
}
