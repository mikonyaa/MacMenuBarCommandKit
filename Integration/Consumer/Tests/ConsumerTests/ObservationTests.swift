import AppKit
import Combine
import MacMenuBarCommandKit
import SwiftUI
import XCTest

@MainActor
final class ObservationTests: XCTestCase {
    func testPublicStoreForwardsReplacementWithoutQueryMutation() {
        let store = CommandStore(registry: CommandRegistry(commands: commands(1)))
        var events = 0
        let subscription = store.objectWillChange.sink { events += 1 }
        store.registry.replaceCommands(commands(30))
        store.registry.replaceCommands([])
        store.registry.replaceCommands(commands(1, prefix: "Reloaded"))
        XCTAssertEqual(events, 3)
        XCTAssertEqual(store.query, "")
        withExtendedLifetime(subscription) {}
    }

    func testHostedRowsObserveOnlyPublicStore() async throws {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        application.finishLaunching()
        let store = CommandStore(registry: CommandRegistry(commands: commands(1)))
        let window = NSWindow(
            contentRect: NSRect(x: 40, y: 40, width: 600, height: 900),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        let rows = VisibleRows()
        let host = NSHostingView(rootView: ConsumerRows(store: store, rows: rows))
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        try await settle()
        XCTAssertTrue(rows.titles.contains("Consumer Item 001"))
        store.registry.replaceCommands(commands(30))
        try await settle()
        XCTAssertTrue(rows.titles.contains("Consumer Item 030"), "Visible hosted rows must redraw after replacement")
        store.registry.replaceCommands([])
        try await settle()
        XCTAssertTrue(rows.titles.contains("No commands"))
        store.registry.replaceCommands(commands(1, prefix: "Reloaded"))
        try await settle()
        XCTAssertTrue(rows.titles.contains("Reloaded Item 001"))
    }

    func testAppOwnedHundredCommandsResolveCurrentMetadata() {
        let registry = CommandRegistry(commands: commands(100))
        var received: [String] = []
        for command in registry.commands {
            registry.register(command.id) { current in
                received.append(current.title)
                return .success(current.title)
            }
        }
        let store = CommandStore(registry: registry)
        let stale = registry.commands[99]
        registry.replaceCommands(commands(100, prefix: "Updated"))
        XCTAssertTrue(store.perform(stale).succeeded)
        XCTAssertEqual(received, ["Updated Item 100"])
        registry.replaceCommands([])
        XCTAssertFalse(store.perform(stale).succeeded)
        XCTAssertEqual(received.count, 1)
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(150))
    }

    private func commands(_ count: Int, prefix: String = "Consumer") -> [CommandItem] {
        (1...max(1, count)).prefix(count).map { index in
            CommandItem(
                id: CommandID(rawValue: "independent.item.\(index)"),
                title: String(format: "%@ Item %03d", prefix, index),
                subtitle: "App-owned consumer command", systemImage: "command", category: .productivity
            )
        }
    }
}

@MainActor
private final class VisibleRows {
    var titles: Set<String> = []
}

private struct ConsumerRows: View {
    @ObservedObject var store: CommandStore
    let rows: VisibleRows

    var body: some View {
        VStack {
            if store.filteredCommands.isEmpty {
                Text("No commands")
                    .onAppear { rows.titles.insert("No commands") }
                    .onDisappear { rows.titles.remove("No commands") }
            }
            ForEach(store.filteredCommands) { command in
                Text(command.title)
                    .id(command.title)
                    .onAppear { rows.titles.insert(command.title) }
                    .onDisappear { rows.titles.remove(command.title) }
            }
        }
    }
}
