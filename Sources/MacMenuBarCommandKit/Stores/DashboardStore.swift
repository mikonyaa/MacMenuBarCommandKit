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

    private var commandRunCount: Int
    private var focusMinutes: Int
    private var inboxItems: Int
    private var focusActive: Bool

    public init(
        state: DashboardContentState = .loaded,
        activities: [ActivityItem] = ActivityItem.demo,
        metrics: [MetricCard] = MetricCard.demo
    ) {
        self.state = state
        self.activities = activities
        self.metrics = metrics
        commandRunCount = 42
        focusMinutes = 150
        inboxItems = 7
        focusActive = false
    }

    public func loadDemoContent() {
        state = .loaded
        activities = ActivityItem.demo
        commandRunCount = 42
        focusMinutes = 150
        inboxItems = 7
        focusActive = false
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

    public func record(command: CommandItem, summary: String) {
        state = .loaded
        commandRunCount += 1

        switch command.action {
        case .newNote:
            inboxItems += 1
        case .startTimer:
            focusMinutes += 25
            focusActive = true
        case .toggleFocusMode:
            focusActive.toggle()
        case .captureClipboard:
            if !summary.localizedCaseInsensitiveContains("clipboard is empty") {
                inboxItems += 1
            }
        case .clearInbox:
            inboxItems = 0
        case .copyStatusReport, .openDashboard, .openSettings:
            break
        }

        metrics = DashboardStore.metrics(
            commandRunCount: commandRunCount,
            focusMinutes: focusMinutes,
            inboxItems: inboxItems,
            focusActive: focusActive
        )
        activities.removeAll { $0.title == command.title && $0.timestamp == "Just now" }
        activities.insert(.commandActivity(for: command, summary: summary), at: 0)
        if activities.count > 6 {
            activities.removeLast(activities.count - 6)
        }
    }

    private static func metrics(
        commandRunCount: Int,
        focusMinutes: Int,
        inboxItems: Int,
        focusActive: Bool
    ) -> [MetricCard] {
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
                value: focusActive ? "Active" : DashboardStore.focusDuration(from: focusMinutes),
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

    private static func focusDuration(from minutes: Int) -> String {
        let hours = Double(minutes) / 60
        return String(format: "%.1fh", hours)
    }
}
