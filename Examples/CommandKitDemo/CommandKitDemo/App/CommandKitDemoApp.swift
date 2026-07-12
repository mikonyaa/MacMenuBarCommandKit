import AppKit
import MacMenuBarCommandKit
import SwiftUI

@main
struct CommandKitDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    @StateObject private var commandRegistry: CommandRegistry
    @StateObject private var commandStore: CommandStore
    @StateObject private var dashboardStore: DashboardStore
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var launchAtLoginService: LaunchAtLoginService
    @StateObject private var demoRuntime: DemoCommandRuntime

    init() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)
        let runtime = DemoCommandRuntime()
        _commandRegistry = StateObject(wrappedValue: registry)
        _commandStore = StateObject(wrappedValue: CommandStore(registry: registry))
        _dashboardStore = StateObject(
            wrappedValue: DashboardStore(
                state: .loaded,
                activities: ActivityItem.demo,
                metrics: runtime.metrics
            )
        )
        _settingsStore = StateObject(wrappedValue: SettingsStore())
        _launchAtLoginService = StateObject(wrappedValue: LaunchAtLoginService())
        _demoRuntime = StateObject(wrappedValue: runtime)
    }

    var body: some Scene {
        WindowGroup("CommandKit", id: "main") {
            DemoRootView(
                commandStore: commandStore,
                dashboardStore: dashboardStore,
                settingsStore: settingsStore,
                onCommand: handleCommand,
                reloadDemoContent: reloadDemoContent
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
            .onAppear {
                configureHandlers()
                configureForLaunchArguments()
            }
        }
        .defaultSize(width: 1080, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                commandButton(.newNote)
            }

            CommandGroup(replacing: .appSettings) {
                commandButton(.openSettings)
            }

            CommandMenu("CommandKit") {
                Button("Command Palette") {
                    commandStore.presentPalette()
                }
                .keyboardShortcut("k", modifiers: .command)

                commandButton(.startTimer)
                commandButton(.captureClipboard)
                commandButton(.copyStatusReport)
                commandButton(.clearInbox)

                Divider()

                commandButton(.openDashboard)
                commandButton(.toggleFocusMode)
            }
        }

        MenuBarExtra("CommandKit", systemImage: "sparkles") {
            MenuBarDashboard(
                commandStore: commandStore,
                dashboardStore: dashboardStore,
                settingsStore: settingsStore,
                onCommand: handleCommand,
                openMainWindow: openMainWindow,
                openSettings: { openSettings() },
                quit: quit
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
        }
        .menuBarExtraStyle(.window)

        Settings {
            CommandKitSettingsView(
                settingsStore: settingsStore,
                launchService: launchAtLoginService,
                commands: commandRegistry.commands
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
        }
    }

    @MainActor
    private func handleCommand(_ command: CommandItem) {
        let result = commandStore.perform(command)
        if result.succeeded {
            demoRuntime.recordSuccessfulRun()
        }

        dashboardStore.replaceMetrics(demoRuntime.metrics)
        dashboardStore.record(
            command: command,
            summary: result.summary,
            tone: demoRuntime.tone(for: command.id, result: result)
        )
    }

    @MainActor
    private func perform(_ id: CommandID) {
        guard let command = commandRegistry.command(for: id) else {
            return
        }
        handleCommand(command)
    }

    @ViewBuilder
    private func commandButton(_ id: CommandID) -> some View {
        if let command = commandRegistry.command(for: id) {
            Button(command.title) {
                handleCommand(command)
            }
            .demoKeyboardShortcut(command.shortcut)
        }
    }

    @MainActor
    private func configureHandlers() {
        commandRegistry.register(.newNote) { _ in
            .success(demoRuntime.createNote())
        }
        commandRegistry.register(.startTimer) { _ in
            let summary = demoRuntime.startTimer()
            commandStore.setFocusModeEnabled(true)
            return .success(summary)
        }
        commandRegistry.register(.captureClipboard) { _ in
            .success(try demoRuntime.captureClipboard())
        }
        commandRegistry.register(.copyStatusReport) { _ in
            .success(demoRuntime.copyStatusReport(recentCommandCount: commandStore.recentCommands.count))
        }
        commandRegistry.register(.clearInbox) { _ in
            .success(demoRuntime.clearInbox())
        }
        commandRegistry.register(.openDashboard) { _ in
            openMainWindow()
            return .success("Opened the main dashboard.")
        }
        commandRegistry.register(.toggleFocusMode) { _ in
            let summary = demoRuntime.toggleFocus()
            commandStore.setFocusModeEnabled(demoRuntime.focusActive)
            return .success(summary)
        }
        commandRegistry.register(.openSettings) { _ in
            openSettings()
            return .success("Opened Settings.")
        }
    }

    @MainActor
    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @MainActor
    private func reloadDemoContent() {
        dashboardStore.loadContent(
            activities: ActivityItem.demo,
            metrics: demoRuntime.metrics
        )
    }

    @MainActor
    private func configureForLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--show-palette") {
            commandStore.presentPalette()
        }
        if arguments.contains("--empty") {
            dashboardStore.showEmpty()
        }
        if arguments.contains("--error") {
            dashboardStore.showError("Preview error state for template authors.")
        }
        if arguments.contains("--loading") {
            dashboardStore.showLoading()
        }
    }
}
