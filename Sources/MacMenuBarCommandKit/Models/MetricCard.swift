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

}
