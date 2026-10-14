import AppKit
import SwiftUI
import Vision
import XCTest
import MacMenuBarCommandKit

@MainActor
final class SettingsRecoveryViewTests: XCTestCase {
    func testFakeErrorApprovalAndForegroundAreRenderedWithoutSystemRegistration() async throws {
        let suite = "CommandKitTests.SettingsView.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let controller = RenderingLoginController()
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.finishLaunching()
        let window = NSWindow(contentRect: NSRect(x: 30, y: 30, width: 610, height: 440),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: CommandKitSettingsView(
            settingsStore: SettingsStore(defaults: defaults), launchController: controller, commands: []
        ).background(.background))
        window.orderFront(nil)
        defer { window.close() }
        try await settle()
        let error = try text(in: window)
        XCTAssertTrue(error.contains("Injected registration failure"), error)
        XCTAssertTrue(error.contains("Retry Status Check"), error)
        controller.nextStatus = .requiresApproval
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        try await settle()
        let approval = try text(in: window)
        XCTAssertTrue(approval.contains("Requires Approval"), approval)
        XCTAssertTrue(approval.contains("Open Login Items Settings"), approval)
        controller.nextStatus = .enabled
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
        try await settle()
        XCTAssertTrue(try text(in: window).contains("Enabled"))
        XCTAssertEqual(controller.registrationCalls, 0)
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

@MainActor
private final class RenderingLoginController: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus = .error("Injected registration failure")
    var nextStatus: LaunchAtLoginStatus = .error("Injected registration failure")
    var isEnabled: Bool { status == .enabled }
    var registrationCalls = 0
    func refresh() { status = nextStatus }
    func setEnabled(_ isEnabled: Bool) { registrationCalls += 1 }
    func openLoginItemsSettings() {}
}
