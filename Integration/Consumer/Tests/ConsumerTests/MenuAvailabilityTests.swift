import AppKit
import MacMenuBarCommandKit
import SwiftUI
import Vision
import XCTest

@MainActor
final class MenuAvailabilityTests: XCTestCase {
    func testNativeMenuRendersCommandsInEveryDataStateAndUpdatesMetadata() async throws {
        let suite = "CommandKitTests.ConsumerMenu.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let store = CommandStore(registry: CommandRegistry(commands: commands(1)))
        store.registry.register("consumer.menu.1") { _ in .success("Independent action") }
        for state in [DashboardContentState.loaded, .empty, .error("Data unavailable"), .loading] {
            let dashboard = DashboardStore(state: state)
            let window = windowFor(store: store, dashboard: dashboard, settings: settings)
            try await settle()
            XCTAssertTrue(try text(in: window).contains("Menu Command 001"), "Commands must remain visible in \(state)")
            XCTAssertTrue(store.perform("consumer.menu.1").succeeded)
            window.close()
        }
        let window = windowFor(store: store, dashboard: DashboardStore(state: .empty), settings: settings)
        defer { window.close() }
        store.registry.replaceCommands(commands(30))
        try await settle()
        let expanded = try text(in: window)
        XCTAssertTrue(expanded.contains("Show all 30 commands"), expanded)
        store.registry.replaceCommands(commands(1, prefix: "Reloaded"))
        try await settle()
        XCTAssertTrue(try text(in: window).contains("Reloaded Menu Command 001"))
        store.query = "no-match"
        try await settle()
        XCTAssertTrue(try text(in: window).contains("No commands match this search"))
    }

    private func windowFor(store: CommandStore, dashboard: DashboardStore, settings: SettingsStore) -> NSWindow {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        application.finishLaunching()
        let window = NSWindow(contentRect: NSRect(x: 20, y: 20, width: 390, height: 620),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: MenuBarDashboard(
            commandStore: store, dashboardStore: dashboard, settingsStore: settings,
            onCommand: { _ = store.perform($0) }, openMainWindow: {}, openSettings: {}, quit: {}
        ).background(.background))
        window.orderFront(nil)
        return window
    }

    private func commands(_ count: Int, prefix: String = "Independent") -> [CommandItem] {
        (1...count).map { index in
            CommandItem(id: CommandID(rawValue: "consumer.menu.\(index)"),
                        title: String(format: "%@ Menu Command %03d", prefix, index), subtitle: "Independent of data state",
                        systemImage: "command", category: .system)
        }
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
        drainRunLoop()
    }

    private func drainRunLoop() { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }

    private func text(in window: NSWindow) throws -> String {
        let view = try XCTUnwrap(window.contentView)
        view.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: XCTUnwrap(bitmap.cgImage)).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}
