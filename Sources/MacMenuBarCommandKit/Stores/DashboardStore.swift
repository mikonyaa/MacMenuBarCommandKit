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
        activities: [ActivityItem] = ActivityItem.demo,
        metrics: [MetricCard] = MetricCard.demo
    ) {
        self.state = state
        self.activities = activities
        self.metrics = metrics
    }

    public func loadDemoContent() {
        state = .loaded
        activities = ActivityItem.demo
        metrics = MetricCard.demo
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
}
