import Foundation

public enum DashboardContentState: Equatable, Sendable {
    case loading
    case loaded
    case empty
    case error(String)
}

@MainActor
public final class DashboardStore: ObservableObject {
    @Published public private(set) var state: DashboardContentState
    @Published public private(set) var activities: [ActivityItem]
    @Published public private(set) var metrics: [MetricCard]

    public init(
        state: DashboardContentState = .loaded,
        activities: [ActivityItem] = [],
        metrics: [MetricCard] = []
    ) {
        self.state = state
        self.activities = activities
        self.metrics = metrics
    }

    public func loadContent(
        activities: [ActivityItem],
        metrics: [MetricCard]
    ) {
        state = .loaded
        self.activities = activities
        self.metrics = metrics
    }

    public func showLoading() {
        state = .loading
    }

    public func showEmpty() {
        state = .empty
        activities = []
        metrics = []
    }

    public func showError(_ message: String = "Demo data could not be loaded.") {
        state = .error(message)
    }

    public func replaceMetrics(_ metrics: [MetricCard]) {
        self.metrics = metrics
        if state != .loading {
            state = .loaded
        }
    }

    public func record(
        command: CommandItem,
        summary: String,
        tone: ActivityTone = .neutral
    ) {
        state = .loaded
        activities.removeAll { $0.title == command.title && $0.timestamp == "Just now" }
        activities.insert(.commandActivity(for: command, summary: summary, tone: tone), at: 0)
        if activities.count > 6 {
            activities.removeLast(activities.count - 6)
        }
    }

}
