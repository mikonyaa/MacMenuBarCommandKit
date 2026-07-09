import XCTest
@testable import MacMenuBarCommandKit

@MainActor
final class CommandKitTests: XCTestCase {
    func testRegistryFiltersByTitleCategoryAndShortcut() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)

        XCTAssertEqual(registry.filteredCommands(matching: "timer").map(\.action), [.startTimer])
        XCTAssertEqual(registry.filteredCommands(matching: "ai clipboard").map(\.action), [.summarizeClipboard])
        XCTAssertEqual(registry.filteredCommands(matching: "cmd unknown").count, 0)
    }

    func testCommandStorePerformsAndTracksRecentCommands() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)
        let store = CommandStore(registry: registry)

        store.perform(.newNote)
        store.perform(.toggleFocusMode)

        XCTAssertEqual(store.recentCommands.first?.action, .toggleFocusMode)
        XCTAssertEqual(store.recentCommands.map(\.action), [.toggleFocusMode, .newNote])
        XCTAssertTrue(store.isFocusModeEnabled)
        XCTAssertEqual(store.lastActionSummary, "Focus mode enabled.")
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
