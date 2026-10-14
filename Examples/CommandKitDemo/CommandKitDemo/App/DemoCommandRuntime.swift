import AppKit
import Combine
import MacMenuBarCommandKit

struct DemoAttempt: Identifiable {
    let id = UUID()
    let title: String
    let result: CommandExecutionResult
    let date: Date

    var activity: ActivityItem {
        ActivityItem(
            id: id.uuidString, title: "\(title) · \(result.succeeded ? "Succeeded" : "Failed")",
            subtitle: result.summary, systemImage: result.succeeded ? "checkmark.circle" : "exclamationmark.triangle",
            timestamp: date.formatted(date: .omitted, time: .shortened), tone: result.succeeded ? .success : .warning
        )
    }
}

@MainActor
final class DemoCommandRuntime: ObservableObject {
    let inbox: DemoInbox
    let timer: DemoTimer
    let dashboard: DashboardStore
    @Published var isNoteEditorPresented = false
    @Published private(set) var attempts: [DemoAttempt] = []
    private(set) var successfulCommands = 0
    private let clipboard: any DemoClipboard
    private let clock: any DemoClock
    private let automaticallyTicks: Bool
    private var observations: Set<AnyCancellable> = []
    private var ticker: AnyCancellable?
    var onTimerFinished: (() -> Void)?

    init(
        settingsStore: SettingsStore,
        clipboard: any DemoClipboard = PasteboardClipboard(pasteboard: .general),
        clock: any DemoClock = WallClock(),
        timerDuration: TimeInterval = 25 * 60,
        automaticallyTicks: Bool = true,
        observeSystemEvents: Bool = true
    ) {
        self.clipboard = clipboard
        self.clock = clock
        self.automaticallyTicks = automaticallyTicks
        let inbox = DemoInbox()
        inbox.setDemoDataEnabled(settingsStore.settings.demoDataEnabled)
        self.inbox = inbox
        let timer = DemoTimer(clock: clock, duration: timerDuration)
        self.timer = timer
        dashboard = DashboardStore(
            state: settingsStore.settings.demoDataEnabled ? .loaded : .empty,
            activities: Self.sampleActivities(inbox), metrics: Self.metrics(0, inbox, timer)
        )
        inbox.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &observations)
        timer.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &observations)
        settingsStore.$settings.map(\.demoDataEnabled).removeDuplicates().dropFirst().sink { [weak self] enabled in
            guard let self else { return }
            // Removing samples preserves real entries, attempts, and timer state.
            self.inbox.setDemoDataEnabled(enabled)
            self.refreshDashboard()
        }.store(in: &observations)
        if observeSystemEvents {
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
                .sink { [weak self] _ in self?.reconcileTimer() }.store(in: &observations)
            NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
                .sink { [weak self] _ in self?.reconcileTimer() }.store(in: &observations)
        }
    }

    func record(title: String, result: CommandExecutionResult, countsAsRequest: Bool = true) {
        if result.succeeded && countsAsRequest { successfulCommands += 1 }
        attempts.insert(DemoAttempt(title: title, result: result, date: clock.now()), at: 0)
        attempts = Array(attempts.prefix(30))
        refreshDashboard()
    }

    func beginNote() -> CommandExecutionResult {
        guard !isNoteEditorPresented else { return .failure("The note editor is already open.") }
        isNoteEditorPresented = true
        return .success("Opened note editor. Save to add a session entry.")
    }

    func saveNote(_ text: String) -> CommandExecutionResult {
        do {
            try inbox.add(text, kind: .note)
            isNoteEditorPresented = false
            refreshDashboard()
            return .success("Saved a note to the session inbox.")
        } catch { return .failure(error.localizedDescription) }
    }

    func cancelNote() {
        isNoteEditorPresented = false
    }

    func captureClipboard() throws -> CommandExecutionResult {
        guard let text = clipboard.readText(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DemoCommandError.emptyClipboard
        }
        try inbox.add(text, kind: .clipboard)
        refreshDashboard()
        return .success("Captured \(text.utf8.count) bytes into the session inbox.")
    }

    func copyEntry(_ id: UUID) -> CommandExecutionResult {
        guard let entry = inbox.entries.first(where: { $0.id == id }) else { return .failure("That inbox entry was removed.") }
        return write(entry.text, summary: "Copied inbox text to the clipboard.")
    }

    func deleteEntry(_ id: UUID) -> CommandExecutionResult {
        guard inbox.delete(id) else { return .failure("That inbox entry was already removed.") }
        refreshDashboard()
        return .success("Deleted one session entry.")
    }

    func clearInbox() -> CommandExecutionResult {
        let count = inbox.clear()
        refreshDashboard()
        if count == 0 { return .success("The session inbox is already empty. No entries were deleted.") }
        return .success("Deleted \(count) session entries. Undo Clear is available until the next inbox change.")
    }

    func undoClear() -> CommandExecutionResult {
        guard inbox.undoClear() else { return .failure("There is no Clear operation to undo.") }
        refreshDashboard()
        return .success("Restored the cleared session entries.")
    }

    func copyStatusReport() -> CommandExecutionResult {
        let report = """
        CommandKit session status
        Successful command requests: \(successfulCommands)
        History records (requests / timer events): \(attempts.count)
        Timer: \(timer.summary)
        Completed focus seconds: \(Int(timer.completedDuration))
        Inbox entries: \(inbox.entries.count) (including samples)
        Storage: session only; lost on app quit or Clear
        """
        return write(report, summary: "Copied session status report to the clipboard.")
    }

    private func write(_ text: String, summary: String) -> CommandExecutionResult {
        clipboard.writeText(text) ? .success(summary) : .failure("The clipboard rejected the write. Try again.")
    }

    func startTimer() -> CommandExecutionResult {
        reconcileTimer()
        let result = timer.start()
        if result.succeeded && automaticallyTicks {
            ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                .sink { [weak self] _ in self?.reconcileTimer() }
        }
        refreshDashboard()
        return result
    }

    func cancelTimer() -> CommandExecutionResult {
        reconcileTimer()
        let result = timer.cancel()
        ticker = nil
        refreshDashboard()
        return result
    }

    func reconcileTimer() {
        let wasRunning = timer.state == .running
        let finished = timer.reconcile()
        if timer.state != .running { ticker = nil }
        if finished {
            record(title: "Timer completed (clock event)", result: .success("Focus block finished. Completed time is now counted."), countsAsRequest: false)
            onTimerFinished?()
        } else if wasRunning {
            refreshDashboard()
        }
    }

    private func refreshDashboard() {
        dashboard.loadContent(
            activities: attempts.map(\.activity) + Self.sampleActivities(inbox),
            metrics: Self.metrics(successfulCommands, inbox, timer)
        )
    }

    private static func sampleActivities(_ inbox: DemoInbox) -> [ActivityItem] {
        guard inbox.entries.contains(where: { $0.isSample }) else { return [] }
        return [ActivityItem(
            id: "sample-information", title: "Sample inbox entries",
            subtitle: "Demonstration content. No command was executed.", systemImage: "tray",
            timestamp: "Sample", tone: .neutral
        )]
    }

    private static func metrics(_ count: Int, _ inbox: DemoInbox, _ timer: DemoTimer) -> [MetricCard] {
        [
            MetricCard(id: "commands", title: "Commands", value: "\(count)",
                       caption: "successful requests this session", systemImage: "command", trend: .flat),
            MetricCard(id: "focus", title: "Timer", value: timer.state == .running ? timer.remainingText : timer.state.rawValue.capitalized,
                       caption: "\(Int(timer.completedDuration / 60)) minutes completed", systemImage: "timer", trend: .flat),
            MetricCard(id: "inbox", title: "Inbox", value: "\(inbox.entries.count)",
                       caption: "session entries, including samples", systemImage: "tray", trend: .flat)
        ]
    }
}
