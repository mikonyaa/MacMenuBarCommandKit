import AppKit
import MacMenuBarCommandKit
import SwiftUI
import Vision
import XCTest

@MainActor
final class NativePaletteTests: XCTestCase {
    func testNativeKeysScrollToHundredthAndReturnDispatchesOnce() async throws {
        let fixture = PaletteFixture()
        let window = makeWindow(fixture)
        defer { window.close() }
        try await settle()
        fixture.store.presentPalette()
        try await settle()
        XCTAssertTrue(window.firstResponder is NSTextView, "Responder: \(String(describing: window.firstResponder))")
        for _ in 0..<99 {
            key(.downArrow, code: 125, window: window)
            try await Task.sleep(for: .milliseconds(5))
        }
        try await settle()
        let image = try capture(window, name: "consumer-hundredth")
        let text = try recognizedText(image)
        XCTAssertTrue(text.contains("Item 100"), "Selected bottom row must be visible in native rendered pixels: \(text)")
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertEqual(fixture.received, ["independent.item.100"])
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertEqual(fixture.received.count, 1)
    }

    func testNativeReplacementSelectionQueryAndNoMatchEscape() async throws {
        let fixture = PaletteFixture()
        let window = makeWindow(fixture)
        defer { window.close() }
        try await settle()
        fixture.store.presentPalette()
        try await settle()
        key(.downArrow, code: 125, window: window)
        try await settle()
        fixture.store.registry.replaceCommands(Array(fixture.store.registry.commands.reversed()))
        try await settle()
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertEqual(fixture.received, ["independent.item.2"], "Reorder preserves selected ID")
        fixture.store.presentPalette()
        try await settle()
        fixture.store.registry.replaceCommands(Array(fixture.store.registry.commands.dropFirst()))
        try await settle()
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertEqual(fixture.received.last, "independent.item.99", "Removing selected metadata repairs selection")
        fixture.store.presentPalette()
        fixture.store.query = "Item 090"
        try await settle()
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertEqual(fixture.received.last, "independent.item.90")
        fixture.store.presentPalette()
        fixture.store.query = "no-match"
        try await settle()
        let count = fixture.received.count
        key(.return, code: 36, window: window)
        try await settle()
        XCTAssertTrue(fixture.store.isPalettePresented)
        XCTAssertEqual(fixture.received.count, count)
        key(.escape, code: 53, window: window)
        try await settle()
        XCTAssertFalse(fixture.store.isPalettePresented)
    }

    func testEscapeRestoresThePreviouslyFocusedControlWhenWindowIsKey() async throws {
        let fixture = PaletteFixture()
        let window = makeWindow(fixture)
        defer { window.close() }
        try await settle()
        try XCTSkipUnless(window.isKeyWindow, "The hosted test process cannot acquire a key window; active-window focus remains a native UI gate")
        let previous = (window.firstResponder as? NSTextView)?.delegate as AnyObject?
        XCTAssertNotNil(previous)
        fixture.store.presentPalette()
        try await settle()
        key(.escape, code: 53, window: window)
        try await settle()
        let restored = (window.firstResponder as? NSTextView)?.delegate as AnyObject?
        XCTAssertTrue(restored === previous, "Escape restores the prior control, including its field editor")
    }

    private func makeWindow(_ fixture: PaletteFixture) -> NSWindow {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        application.finishLaunching()
        let window = NSWindow(contentRect: NSRect(x: 50, y: 50, width: 800, height: 680),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: NativePaletteWorkspace(fixture: fixture, store: fixture.store))
        application.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeKey()
        window.makeMain()
        return window
    }

    private func key(_ value: XCUIKeyboardKey, code: UInt16, window: NSWindow) {
        let characters: String
        switch value {
        case .downArrow: characters = "\u{f701}"
        case .escape: characters = "\u{1b}"
        default: characters = "\r"
        }
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                                    timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                    context: nil, characters: characters, charactersIgnoringModifiers: characters,
                                    isARepeat: false, keyCode: code)!
        NSApp.sendEvent(event)
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
        drainRunLoop()
    }

    private func drainRunLoop() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    private func capture(_ window: NSWindow, name: String) throws -> CGImage {
        let view = try XCTUnwrap(window.contentView)
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        if let directory = ProcessInfo.processInfo.environment["CONSUMER_CAPTURE_DIR"] {
            try bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name + ".png"))
        }
        return try XCTUnwrap(bitmap.cgImage)
    }

    private func recognizedText(_ image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}

@MainActor
private final class PaletteFixture {
    let store: CommandStore
    var received: [CommandID] = []

    init() {
        let commands = (1...100).map { index in
            CommandItem(id: CommandID(rawValue: "independent.item.\(index)"), title: String(format: "Independent Item %03d", index),
                        subtitle: "Public API native consumer", systemImage: "command", category: .productivity)
        }
        let registry = CommandRegistry(commands: commands)
        store = CommandStore(registry: registry)
        for command in commands {
            registry.register(command.id) { [weak self] current in
                self?.received.append(current.id)
                return .success("Executed \(current.title)")
            }
        }
    }

    func run(_ command: CommandItem) { _ = store.perform(command) }
}

private struct NativePaletteWorkspace: View {
    let fixture: PaletteFixture
    @ObservedObject var store: CommandStore
    @State private var backgroundText = ""
    @FocusState private var backgroundFocused: Bool

    var body: some View {
        CommandPaletteOverlay(commandStore: store, onCommand: fixture.run) {
            TextField("Previous focus", text: $backgroundText)
                .focused($backgroundFocused)
                .padding(40)
                .onAppear { backgroundFocused = true }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
