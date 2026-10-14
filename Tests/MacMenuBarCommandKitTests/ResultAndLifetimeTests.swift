import Combine
import XCTest
@testable import MacMenuBarCommandKit

@MainActor
final class ResultAndLifetimeTests: XCTestCase {
    func testResultsKeepSeverityForEveryExecutionPath() {
        struct ExpectedError: LocalizedError { var errorDescription: String? { "Expected failure" } }
        let items = ["success", "failure", "throwing", "missing"].map { id in
            CommandItem(id: CommandID(rawValue: id), title: id, subtitle: "", systemImage: "command", category: .system)
        }
        let registry = CommandRegistry(commands: items)
        registry.register("success") { _ in .success("Completed") }
        registry.register("failure") { _ in .failure("Explicit rejection") }
        registry.register("throwing") { _ in throw ExpectedError() }
        let store = CommandStore(registry: registry)
        XCTAssertNil(store.latestResult)
        var summaries: Set<String> = []
        for (id, succeeded) in [("success", true), ("failure", false), ("throwing", false), ("missing", false), ("unknown", false)] {
            let result = store.perform(CommandID(rawValue: id))
            XCTAssertEqual(result.succeeded, succeeded)
            XCTAssertEqual(store.latestResult, result)
            XCTAssertEqual(store.lastActionSummary, result.summary)
            summaries.insert(result.summary)
        }
        XCTAssertEqual(summaries.count, 5, "Success, explicit, throwing, missing and unknown results remain distinguishable")
        XCTAssertEqual(store.recentCommands.map(\.id), ["missing", "throwing", "failure", "success"])
        store.updateLastActionSummary("Informational status")
        XCTAssertNil(store.latestResult, "A legacy summary must not manufacture success")
        store.updateLastActionResult(.failure("Editor rejected input"))
        XCTAssertEqual(store.latestResult, .failure("Editor rejected input"))
        store.updateLastActionResult(.failure("Ready"))
        XCTAssertTrue(store.hasActionSummary, "Typed failure cannot be hidden by the legacy placeholder text")
    }

    func testRegistryBridgeHasNoRetentionCycle() {
        let registry = CommandRegistry()
        weak var releasedStore: CommandStore?
        do {
            let store = CommandStore(registry: registry)
            releasedStore = store
        }
        XCTAssertNil(releasedStore)
        registry.replaceCommands([])
    }

    func testSettingsPrefixesDoNotCollide() {
        let name = "CommandKitTests.Prefix.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let first = SettingsStore(defaults: defaults, keyPrefix: "First.")
        let second = SettingsStore(defaults: defaults, keyPrefix: "Second.")
        first.update { $0.demoDataEnabled = false; $0.themePreference = .dark }
        XCTAssertTrue(second.settings.demoDataEnabled)
        XCTAssertEqual(SettingsStore(defaults: defaults, keyPrefix: "First.").settings.themePreference, .dark)
        XCTAssertNil(defaults.object(forKey: SettingsStore.Key.demoDataEnabled))
    }
}
