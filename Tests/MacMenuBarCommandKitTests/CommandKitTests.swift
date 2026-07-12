import XCTest
@testable import MacMenuBarCommandKit

@MainActor
final class CommandKitTests: XCTestCase {
    private let noteID: CommandID = "note.new"
    private let timerID: CommandID = "focus.start"

    func testCommandIDIsStringBackedAndCodable() throws {
        let encoded = try JSONEncoder().encode(noteID)
        let decoded = try JSONDecoder().decode(CommandID.self, from: encoded)

        XCTAssertEqual(decoded.rawValue, "note.new")
        XCTAssertEqual(decoded, noteID)
    }

    func testRegistryFiltersMetadataAndResolvesHandlersByID() throws {
        let commands = sampleCommands
        let registry = CommandRegistry(commands: commands)
        registry.register(noteID) { command in
            .success("Ran \(command.title)")
        }

        XCTAssertEqual(registry.filteredCommands(matching: "note ⌘n").map(\.id), [noteID])
        XCTAssertEqual(registry.command(for: timerID)?.title, "Start Timer")
        XCTAssertEqual(try registry.handler(for: noteID)?(commands[0]), .success("Ran New Note"))
    }

    func testCommandStoreUsesRegisteredResultAndTracksRecentCommands() {
        let registry = CommandRegistry(commands: sampleCommands)
        registry.register(noteID) { _ in .success("Created a local note.") }
        registry.register(timerID) { _ in .success("Started a focus timer.") }
        let store = CommandStore(registry: registry)

        XCTAssertEqual(store.perform(noteID), .success("Created a local note."))
        XCTAssertEqual(store.perform(timerID), .success("Started a focus timer."))
        XCTAssertEqual(store.recentCommands.map(\.id), [timerID, noteID])
        XCTAssertEqual(store.lastActionSummary, "Started a focus timer.")
    }

    func testCommandStoreReportsMissingAndThrowingHandlers() {
        enum TestFailure: Error { case expected }

        let registry = CommandRegistry(commands: sampleCommands)
        registry.register(noteID) { _ in throw TestFailure.expected }
        let store = CommandStore(registry: registry)

        XCTAssertFalse(store.perform(timerID).succeeded)
        XCTAssertFalse(store.perform(noteID).succeeded)
        XCTAssertTrue(store.lastActionSummary.contains("New Note"))
    }

    func testDashboardRecordsGenericCommandActivity() {
        let store = DashboardStore(state: .loaded)
        let command = sampleCommands[0]

        store.record(command: command, summary: "Created a local note.", tone: .accent)

        XCTAssertEqual(store.activities.first?.title, "New Note")
        XCTAssertEqual(store.activities.first?.subtitle, "Created a local note.")
        XCTAssertEqual(store.activities.first?.tone, .accent)
    }

    func testSettingsStorePersistsOnlyReusablePreferences() {
        let suiteName = "MacMenuBarCommandKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
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

    func testShortcutDisplayUsesMacSymbols() {
        let shortcut = CommandShortcut(modifiers: [.command, .option], key: "f")
        XCTAssertEqual(shortcut.displayValue, "⌘⌥F")
    }

    private var sampleCommands: [CommandItem] {
        [
            CommandItem(
                id: noteID,
                title: "New Note",
                subtitle: "Capture a short local note.",
                systemImage: "square.and.pencil",
                category: .productivity,
                shortcut: CommandShortcut(key: "N")
            ),
            CommandItem(
                id: timerID,
                title: "Start Timer",
                subtitle: "Begin a focus block.",
                systemImage: "timer",
                category: .focus,
                shortcut: CommandShortcut(modifiers: [.command, .shift], key: "T")
            )
        ]
    }
}
