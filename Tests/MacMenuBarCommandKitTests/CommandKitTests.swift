import XCTest
@testable import MacMenuBarCommandKit

@MainActor
final class CommandKitTests: XCTestCase {
    func testRegistryFiltersByTitleCategoryAndShortcut() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)

        XCTAssertEqual(registry.filteredCommands(matching: "timer").map(\.action), [.startTimer])
        XCTAssertEqual(registry.filteredCommands(matching: "clipboard inbox").map(\.action), [.captureClipboard])
        XCTAssertEqual(registry.filteredCommands(matching: "status report").map(\.action), [.copyStatusReport])
        XCTAssertEqual(registry.filteredCommands(matching: "cmd unknown").count, 0)
    }

    func testDemoCommandsCoverCoreMenuBarWorkflows() {
        XCTAssertEqual(CommandItem.demoCommands.count, 8)
        XCTAssertEqual(
            Set(CommandItem.demoCommands.map(\.action)),
            Set(CommandAction.allCases)
        )
    }

    func testCommandStorePerformsAndTracksRecentCommands() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)
        let store = CommandStore(registry: registry)

        store.perform(.newNote)
        store.perform(.startTimer)

        XCTAssertEqual(store.recentCommands.first?.action, .startTimer)
        XCTAssertEqual(store.recentCommands.map(\.action), [.startTimer, .newNote])
        XCTAssertTrue(store.isFocusModeEnabled)
        XCTAssertEqual(store.lastActionSummary, "Started a 25-minute focus timer.")
    }

    func testDashboardStoreRecordsCommandAsVisibleActivity() {
        let store = DashboardStore()
        let command = CommandItem.demoCommands.first { $0.action == .newNote }!

        store.record(command: command, summary: "Created a local note.")

        XCTAssertEqual(store.state, .loaded)
        XCTAssertEqual(store.activities.first?.title, "New Note")
        XCTAssertEqual(store.activities.first?.subtitle, "Created a local note.")
        XCTAssertEqual(store.metrics.first?.value, "43")
    }

    func testDashboardStoreRecordsClearInboxSideEffect() {
        let store = DashboardStore()
        let command = CommandItem.demoCommands.first { $0.action == .clearInbox }!

        store.record(command: command, summary: "Cleared the local inbox.")

        XCTAssertEqual(store.metrics.first { $0.id == "queue" }?.value, "0")
        XCTAssertEqual(store.activities.first?.title, "Clear Inbox")
    }

    func testSettingsStoreLoadsDefaultsAndPersistsUpdates() {
        let suiteName = "MacMenuBarCommandKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.settings, .defaults)

        store.update {
            $0.menuBarPresentation = .compact
            $0.themePreference = .dark
            $0.demoDataEnabled = false
        }

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.settings.menuBarPresentation, .compact)
        XCTAssertEqual(reloaded.settings.themePreference, .dark)
        XCTAssertFalse(reloaded.settings.demoDataEnabled)
    }

    func testDashboardStoreStateTransitionsAreDeterministic() {
        let store = DashboardStore()
        XCTAssertEqual(store.state, .loaded)
        XCTAssertFalse(store.activities.isEmpty)
        XCTAssertFalse(store.metrics.isEmpty)

        store.showEmpty()
        XCTAssertEqual(store.state, .empty)
        XCTAssertTrue(store.activities.isEmpty)

        store.showError("Failure")
        XCTAssertEqual(store.state, .error("Failure"))

        store.loadDemoContent()
        XCTAssertEqual(store.state, .loaded)
        XCTAssertEqual(store.metrics.count, MetricCard.demo.count)
    }

    func testShortcutDisplayUsesMacSymbols() {
        let shortcut = CommandShortcut(modifiers: [.command, .option], key: "f")
        XCTAssertEqual(shortcut.displayValue, "⌘⌥F")
    }
}
