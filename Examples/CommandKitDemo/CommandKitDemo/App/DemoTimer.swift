import Foundation
import MacMenuBarCommandKit

@MainActor
protocol DemoClock {
    func now() -> Date
}

struct WallClock: DemoClock {
    func now() -> Date { Date() }
}

@MainActor
final class DemoTimer: ObservableObject {
    enum State: String { case idle, running, finished, cancelled }
    @Published private(set) var state: State = .idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var completedDuration: TimeInterval = 0
    private(set) var deadline: Date?
    private let clock: any DemoClock
    private let duration: TimeInterval

    init(clock: any DemoClock = WallClock(), duration: TimeInterval = 25 * 60) {
        precondition(duration > 0 && duration.isFinite)
        self.clock = clock
        self.duration = duration
    }

    func start() -> CommandExecutionResult {
        reconcile()
        guard state != .running else {
            return .failure("A timer is already running. Cancel it before starting another.")
        }
        deadline = clock.now().addingTimeInterval(duration)
        remaining = duration
        state = .running
        return .success("Timer running for \(Int(duration)) seconds. System Focus is unchanged.")
    }

    func cancel() -> CommandExecutionResult {
        reconcile()
        guard state == .running else { return .failure("There is no running timer to cancel.") }
        state = .cancelled
        deadline = nil
        remaining = 0
        return .success("Timer cancelled. No completed focus time was added.")
    }

    /// Derives progress from the deadline, including time spent asleep or away.
    @discardableResult
    func reconcile() -> Bool {
        guard state == .running, let deadline else { return false }
        remaining = max(0, min(duration, deadline.timeIntervalSince(clock.now())))
        guard remaining == 0 else { return false }
        state = .finished
        completedDuration += duration
        return true
    }

    var remainingText: String {
        let seconds = Int(ceil(remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var summary: String {
        switch state {
        case .idle: "Idle · 25-minute timer"
        case .running: "Running · \(remainingText) remaining"
        case .finished: "Finished · focus block completed"
        case .cancelled: "Cancelled · ready for a new timer"
        }
    }
}
