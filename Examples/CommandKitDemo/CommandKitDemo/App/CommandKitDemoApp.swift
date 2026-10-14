import AppKit
import MacMenuBarCommandKit
import SwiftUI

@main
struct CommandKitDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sceneActions = DemoSceneActions()
    @StateObject private var commandRegistry: CommandRegistry
    @StateObject private var commandStore: CommandStore
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var demoRuntime: DemoCommandRuntime
    @State private var configured = false
    private let configuration: DemoLaunchConfiguration

    init() {
        let configuration = DemoLaunchConfiguration()
        self.configuration = configuration
        // Read persisted preferences before creating sample state.
        let settings = SettingsStore(defaults: configuration.defaults)
        let commands = configuration.testCommandCount.map(Self.testCommands) ?? CommandItem.demoCommands
        let registry = CommandRegistry(commands: commands)
        let runtime = DemoCommandRuntime(
            settingsStore: settings, clipboard: configuration.clipboard, timerDuration: configuration.timerDuration
        )
        _commandRegistry = StateObject(wrappedValue: registry)
        _commandStore = StateObject(wrappedValue: CommandStore(registry: registry))
        _settingsStore = StateObject(wrappedValue: settings)
        _demoRuntime = StateObject(wrappedValue: runtime)
    }

    var body: some Scene {
        WindowGroup("CommandKit", id: "main") {
            DemoSceneBridge(actions: sceneActions) {
                DemoRootView(commandStore: commandStore, runtime: demoRuntime, onCommand: handleCommand, onOperation: completeOperation)
                    .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
                    .onAppear { configureOnce() }
                    .task {
                        try? await Task.sleep(for: .milliseconds(150))
                        verifyOwnedLaunch()
                        await captureRequestedSurface()
                    }
            }
        }
        .defaultSize(width: 1280, height: 780)
        .commands {
            DemoCommandMenus(registry: commandRegistry, store: commandStore, actions: sceneActions, onCommand: handleCommand)
        }
        MenuBarExtra("CommandKit", systemImage: "sparkles") {
            DemoSceneBridge(actions: sceneActions) {
                MenuBarDashboard(
                    commandStore: commandStore, dashboardStore: demoRuntime.dashboard, settingsStore: settingsStore,
                    onCommand: handleCommand, openMainWindow: sceneActions.openMainWindow, openSettings: sceneActions.openSettings,
                    quit: { NSApplication.shared.terminate(nil) }
                )
                .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
            }
        }
        .menuBarExtraStyle(.window)
        Settings {
            CommandKitSettingsView(
                settingsStore: settingsStore, launchController: configuration.loginController, commands: commandRegistry.commands
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
        }
    }

    private func handleCommand(_ command: CommandItem) {
        let title = commandRegistry.command(for: command.id)?.title ?? command.title
        let result = commandStore.perform(command.id)
        demoRuntime.record(title: title, result: result)
    }

    private func completeOperation(_ title: String, _ result: CommandExecutionResult) {
        commandStore.updateLastActionResult(result)
        demoRuntime.record(title: title, result: result)
    }

    private func configureOnce() {
        guard !configured else { return }
        configured = true
        commandRegistry.register(.newNote) { _ in
            sceneActions.openMainWindow()
            return demoRuntime.beginNote()
        }
        commandRegistry.register(.startTimer) { _ in demoRuntime.startTimer() }
        commandRegistry.register(.cancelTimer) { _ in demoRuntime.cancelTimer() }
        commandRegistry.register(.captureClipboard) { _ in try demoRuntime.captureClipboard() }
        commandRegistry.register(.copyStatusReport) { _ in demoRuntime.copyStatusReport() }
        commandRegistry.register(.clearInbox) { _ in demoRuntime.clearInbox() }
        commandRegistry.register(.openDashboard) { _ in
            sceneActions.openMainWindow()
            return .success("Opened the main dashboard.")
        }
        commandRegistry.register(.toggleFocusMode) { _ in
            commandStore.setFocusModeEnabled(!commandStore.isFocusModeEnabled)
            return .success("Dashboard focus \(commandStore.isFocusModeEnabled ? "enabled" : "disabled"). System Focus is unchanged.")
        }
        commandRegistry.register(.openSettings) { _ in
            sceneActions.openSettings()
            return .success("Opened Settings.")
        }
        if configuration.testCommandCount != nil {
            for command in commandRegistry.commands {
                commandRegistry.register(command.id) { .success("Executed \($0.id.rawValue)") }
            }
        }
        demoRuntime.onTimerFinished = { [weak commandStore] in
            commandStore?.updateLastActionResult(.success("Timer finished. Completed focus time was counted."))
        }
        let arguments = configuration.arguments
        if arguments.contains("--show-palette") { commandStore.presentPalette() }
        if arguments.contains("--empty") { demoRuntime.dashboard.showEmpty() }
        if arguments.contains("--error") { demoRuntime.dashboard.showError("Preview data error. Independent commands remain available.") }
        if arguments.contains("--loading") { demoRuntime.dashboard.showLoading() }
    }

    private func verifyOwnedLaunch() {
        guard let output = configuration.verifyOutput else { return }
        let result = commandStore.perform(.copyStatusReport)
        let readback = configuration.clipboard.readText() ?? ""
        let health: [String: Any] = [
            "pid": ProcessInfo.processInfo.processIdentifier,
            "bundlePath": Bundle.main.bundleURL.path,
            "executablePath": Bundle.main.executableURL?.path ?? "",
            "hasWindow": NSApp.windows.contains { $0.title == "CommandKit" },
            "demoDataEnabled": settingsStore.settings.demoDataEnabled,
            "sampleCount": demoRuntime.inbox.entries.filter(\.isSample).count,
            "inboxCount": demoRuntime.inbox.entries.count,
            "theme": settingsStore.settings.themePreference.rawValue,
            "menuPresentation": settingsStore.settings.menuBarPresentation.rawValue,
            "actionSucceeded": result.succeeded,
            "clipboardReadbackMatches": readback.hasPrefix("CommandKit session status\n"),
            "summary": result.summary
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: health, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: output), options: .atomic)
        } catch {
            NSLog("Could not write owned launch verification: %@", error.localizedDescription)
        }
    }

    private func captureRequestedSurface() async {
        guard let directory = configuration.captureDirectory, let surface = configuration.captureSurface,
              DemoCapture.surfaces.contains(surface) else { return }
        do {
            try await Task.sleep(for: .milliseconds(600))
            var captureWindow: NSWindow?
            if surface == "settings" {
                sceneActions.openSettings()
            } else if surface == "command-palette" {
                commandStore.presentPalette()
            } else if surface == "menu-dashboard" {
                let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 390, height: 620),
                                      styleMask: [.titled, .closable], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.title = "CommandKit menu surface capture"
                window.contentView = NSHostingView(rootView: MenuBarDashboard(
                    commandStore: commandStore, dashboardStore: demoRuntime.dashboard, settingsStore: settingsStore,
                    onCommand: handleCommand, openMainWindow: sceneActions.openMainWindow, openSettings: sceneActions.openSettings,
                    quit: { NSApp.terminate(nil) }
                ).background(.background))
                window.makeKeyAndOrderFront(nil)
                captureWindow = window
            }
            try await Task.sleep(for: .milliseconds(600))
            guard let window = captureWindow ?? NSApp.keyWindow else { return }
            try DemoCapture.write(window: window, directory: directory, surface: surface, sourceCommit: configuration.captureCommit)
            captureWindow?.close()
        } catch { NSLog("Native content capture failed: %@", error.localizedDescription) }
    }

    private static func testCommands(_ count: Int) -> [CommandItem] {
        (1...count).map { index in
            CommandItem(id: CommandID(rawValue: "fixture.command.\(index)"), title: String(format: "Fixture Command %03d", index),
                        subtitle: "Isolated keyboard fixture", systemImage: "command", category: .productivity)
        }
    }
}
