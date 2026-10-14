import AppKit
import MacMenuBarCommandKit
import XCTest
@testable import CommandKitDemo

@MainActor
final class DemoRuntimeTests: XCTestCase {
    func testOffRelaunchAndTogglePreserveRealEntriesAndPreferences() throws {
        let name = "CommandKitTests.Relaunch.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsStore(defaults: defaults)
        settings.update { $0.demoDataEnabled = false; $0.themePreference = .dark; $0.menuBarPresentation = .compact }
        let reloadedSettings = SettingsStore(defaults: defaults)
        let runtime = makeRuntime(reloadedSettings)
        XCTAssertEqual(runtime.dashboard.state, .empty)
        XCTAssertTrue(runtime.inbox.entries.isEmpty)
        XCTAssertTrue(runtime.attempts.isEmpty)
        XCTAssertEqual(reloadedSettings.settings.themePreference, .dark)
        XCTAssertEqual(reloadedSettings.settings.menuBarPresentation, .compact)
        XCTAssertTrue(runtime.saveNote("Real user note").succeeded)
        let realID = runtime.inbox.entries[0].id
        reloadedSettings.update { $0.demoDataEnabled = true }
        XCTAssertEqual(runtime.inbox.entries.filter(\.isSample).count, 2)
        reloadedSettings.update { $0.themePreference = .light }
        let sampleIDs = runtime.inbox.entries.filter(\.isSample).map(\.id)
        reloadedSettings.update { $0.menuBarPresentation = .balanced }
        XCTAssertEqual(runtime.inbox.entries.filter(\.isSample).map(\.id), sampleIDs)
        reloadedSettings.update { $0.demoDataEnabled = false }
        XCTAssertEqual(runtime.inbox.entries.map(\.id), [realID])
    }

    func testNoteSaveCancelEmptyAndStableIDs() {
        withSettings { settings in
            let runtime = makeRuntime(settings)
            XCTAssertTrue(runtime.beginNote().succeeded)
            XCTAssertFalse(runtime.beginNote().succeeded)
            runtime.cancelNote()
            XCTAssertTrue(runtime.inbox.entries.isEmpty)
            XCTAssertTrue(runtime.beginNote().succeeded)
            XCTAssertFalse(runtime.saveNote(" \n\t").succeeded)
            XCTAssertTrue(runtime.isNoteEditorPresented)
            XCTAssertTrue(runtime.saveNote("A note\nwith two lines").succeeded)
            XCTAssertFalse(runtime.isNoteEditorPresented)
            XCTAssertTrue(runtime.saveNote("A note\nwith two lines").succeeded)
            XCTAssertEqual(Set(runtime.inbox.entries.map(\.id)).count, 2)
        }
    }

    func testClipboardReadIsExplicitAndWriteFailureIsReported() throws {
        try withSettings { settings in
            let clipboard = FakeClipboard()
            let runtime = makeRuntime(settings, clipboard: clipboard)
            XCTAssertEqual(clipboard.reads, 0)
            XCTAssertThrowsError(try runtime.captureClipboard())
            clipboard.text = " \n\t"
            XCTAssertThrowsError(try runtime.captureClipboard())
            clipboard.text = "First line\nSecond line\n"
            XCTAssertTrue(try runtime.captureClipboard().succeeded)
            let entry = try XCTUnwrap(runtime.inbox.entries.first)
            XCTAssertEqual(entry.text, clipboard.text)
            clipboard.acceptsWrite = false
            XCTAssertFalse(runtime.copyEntry(entry.id).succeeded)
            XCTAssertFalse(runtime.copyStatusReport().succeeded)
            clipboard.acceptsWrite = true
            XCTAssertTrue(runtime.copyEntry(entry.id).succeeded)
            XCTAssertEqual(clipboard.text, entry.text)
            XCTAssertTrue(runtime.deleteEntry(entry.id).succeeded)
            XCTAssertFalse(runtime.copyEntry(entry.id).succeeded)
        }
    }

    func testInboxUTF8AndCountLimitsClearUndo() throws {
        let inbox = DemoInbox()
        let boundary = String(repeating: "🙂", count: 4096)
        XCTAssertEqual(boundary.utf8.count, DemoInbox.maximumTextBytes)
        try inbox.add(boundary, kind: .note)
        XCTAssertThrowsError(try inbox.add(boundary + "x", kind: .clipboard))
        for index in 1..<DemoInbox.maximumEntries { try inbox.add("Item \(index)", kind: .note) }
        XCTAssertThrowsError(try inbox.add("Overflow", kind: .note))
        let ids = inbox.entries.map(\.id)
        XCTAssertEqual(Set(ids).count, DemoInbox.maximumEntries)
        XCTAssertEqual(inbox.clear(), DemoInbox.maximumEntries)
        XCTAssertTrue(inbox.undoClear())
        XCTAssertEqual(inbox.entries.map(\.id), ids)
        inbox.clear()
        try inbox.add("New text", kind: .clipboard)
        XCTAssertFalse(inbox.undoClear(), "A subsequent inbox change invalidates Undo Clear")
        XCTAssertEqual(inbox.entries.count, 1)
    }

    func testPrivatePasteboardRoundTrip() {
        let pasteboard = NSPasteboard(name: .init("CommandKitTests.Clipboard.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        let adapter = PasteboardClipboard(pasteboard: pasteboard)
        XCTAssertTrue(adapter.writeText("Own pasteboard\nmultiline"))
        XCTAssertEqual(adapter.readText(), "Own pasteboard\nmultiline")
    }

    func testDeadlineCompletionRepeatedStartCancelAndSleepReconcile() {
        let clock = FakeClock()
        let timer = DemoTimer(clock: clock)
        XCTAssertEqual(timer.state, .idle)
        XCTAssertTrue(timer.start().succeeded)
        let deadline = timer.deadline
        XCTAssertEqual(timer.remaining, 1500)
        XCTAssertEqual(timer.completedDuration, 0)
        clock.date += 60
        timer.reconcile()
        XCTAssertEqual(timer.remaining, 1440)
        XCTAssertFalse(timer.start().succeeded)
        XCTAssertEqual(timer.deadline, deadline)
        clock.date += 1800 // A sleep/foreground gap is reconciled in one call.
        XCTAssertTrue(timer.reconcile())
        XCTAssertEqual(timer.state, .finished)
        XCTAssertEqual(timer.completedDuration, 1500)
        XCTAssertFalse(timer.reconcile())
        XCTAssertEqual(timer.completedDuration, 1500)
        XCTAssertTrue(timer.start().succeeded)
        clock.date += 10
        XCTAssertTrue(timer.cancel().succeeded)
        XCTAssertEqual(timer.state, .cancelled)
        clock.date += 3600
        timer.reconcile()
        XCTAssertEqual(timer.completedDuration, 1500)
    }

    func testRuntimeForegroundCompletionHistoryAndLifetime() {
        withSettings { settings in
            let clock = FakeClock()
            var runtime: DemoCommandRuntime? = DemoCommandRuntime(
                settingsStore: settings, clipboard: FakeClipboard(), clock: clock,
                timerDuration: 2, automaticallyTicks: false, observeSystemEvents: false
            )
            weak var released = runtime
            XCTAssertTrue(runtime!.startTimer().succeeded)
            clock.date += 3
            runtime!.reconcileTimer()
            runtime!.reconcileTimer()
            XCTAssertEqual(runtime!.attempts.count, 1)
            XCTAssertEqual(runtime!.timer.state, .finished)
            runtime!.record(title: "Rejected request", result: .failure("Nothing changed"))
            XCTAssertFalse(runtime!.attempts.first!.result.succeeded)
            XCTAssertTrue(runtime!.attempts.first!.activity.title.contains("Failed"))
            XCTAssertEqual(runtime!.successfulCommands, 0, "A clock event or failed request is not a successful command request")
            runtime!.record(title: "Accepted request", result: .success("Completed"))
            XCTAssertEqual(runtime!.successfulCommands, 1)
            runtime = nil
            XCTAssertNil(released)
        }
    }

    func testForegroundAndWakeNotificationsReconcileOnce() {
        withSettings { settings in
            let clock = FakeClock()
            let runtime = DemoCommandRuntime(
                settingsStore: settings, clipboard: FakeClipboard(), clock: clock,
                timerDuration: 2, automaticallyTicks: false, observeSystemEvents: true
            )
            XCTAssertTrue(runtime.startTimer().succeeded)
            clock.date += 10
            NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
            XCTAssertEqual(runtime.timer.state, .finished)
            XCTAssertEqual(runtime.attempts.count, 1)
            NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
            XCTAssertEqual(runtime.attempts.count, 1)
        }
    }

    func testNativeTickerCompletesAndRuntimeReleasesItsSubscription() async throws {
        let name = "CommandKitTests.Ticker.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsStore(defaults: defaults)
        settings.update { $0.demoDataEnabled = false }
        var runtime: DemoCommandRuntime? = DemoCommandRuntime(
            settingsStore: settings, clipboard: FakeClipboard(), timerDuration: 0.1,
            automaticallyTicks: true, observeSystemEvents: false
        )
        weak var released = runtime
        XCTAssertTrue(runtime!.startTimer().succeeded)
        XCTAssertEqual(runtime!.timer.state, .running)
        XCTAssertEqual(runtime!.timer.completedDuration, 0)
        try await Task.sleep(for: .milliseconds(1300))
        XCTAssertEqual(runtime!.timer.state, .finished)
        XCTAssertEqual(runtime!.attempts.count, 1)
        XCTAssertTrue(runtime!.startTimer().succeeded)
        XCTAssertTrue(runtime!.cancelTimer().succeeded)
        XCTAssertEqual(runtime!.timer.state, .cancelled)
        runtime = nil
        XCTAssertNil(released, "The native repeating subscription must not retain its app-owned runtime")
    }

    private func makeRuntime(_ settings: SettingsStore, clipboard: any DemoClipboard = FakeClipboard()) -> DemoCommandRuntime {
        DemoCommandRuntime(settingsStore: settings, clipboard: clipboard, automaticallyTicks: false, observeSystemEvents: false)
    }

    private func withSettings(_ body: (SettingsStore) throws -> Void) rethrows {
        let name = "CommandKitTests.Runtime.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsStore(defaults: defaults)
        settings.update { $0.demoDataEnabled = false }
        try body(settings)
    }
}

@MainActor
private final class FakeClipboard: DemoClipboard {
    var text: String?
    var acceptsWrite = true
    var reads = 0
    func readText() -> String? { reads += 1; return text }
    func writeText(_ text: String) -> Bool {
        if acceptsWrite { self.text = text }
        return acceptsWrite
    }
}

@MainActor
private final class FakeClock: DemoClock {
    var date = Date(timeIntervalSince1970: 1_000)
    func now() -> Date { date }
}
