enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case today
    case actions
    case recent
    case status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "Today"
        case .actions:
            "Quick Actions"
        case .recent:
            "Command Attempts"
        case .status:
            "System Status"
        }
    }

    var subtitle: String {
        switch self {
        case .today:
            "Overview, metrics, and recent activity"
        case .actions:
            "Search and run available commands"
        case .recent:
            "Review command history and activity"
        case .status:
            "Inspect local template status"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "sun.max"
        case .actions:
            "bolt"
        case .recent:
            "clock.arrow.circlepath"
        case .status:
            "chart.xyaxis.line"
        }
    }
}
