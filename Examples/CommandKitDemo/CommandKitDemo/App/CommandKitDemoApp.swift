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

    init() {
        let registry = CommandRegistry(commands: CommandItem.demoCommands)
        _commandRegistry = StateObject(wrappedValue: registry)
        _commandStore = StateObject(wrappedValue: CommandStore(registry: registry))
        _dashboardStore = StateObject(wrappedValue: DashboardStore())
        _settingsStore = StateObject(wrappedValue: SettingsStore())
        _launchAtLoginService = StateObject(wrappedValue: LaunchAtLoginService())
    }

    var body: some Scene {
        WindowGroup("CommandKit", id: "main") {
            DemoRootView(
                commandStore: commandStore,
                dashboardStore: dashboardStore,
                settingsStore: settingsStore,
                onCommand: handleCommand
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
            .onAppear {
                configureForLaunchArguments()
            }
        }
        .defaultSize(width: 1080, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    perform(.newNote)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("CommandKit") {
                Button("Command Palette") {
                    commandStore.presentPalette()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Start Timer") {
                    perform(.startTimer)
                }
                .keyboardShortcut("T", modifiers: [.command, .shift])

                Button("Capture Clipboard") {
                    perform(.captureClipboard)
                }
                .keyboardShortcut("V", modifiers: [.command, .shift])

                Button("Copy Status Report") {
                    perform(.copyStatusReport)
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])

                Button("Clear Inbox") {
                    perform(.clearInbox)
                }
                .keyboardShortcut("X", modifiers: [.command, .shift])

                Divider()

                Button("Open Dashboard") {
                    openMainWindow()
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("Toggle Focus Mode") {
                    perform(.toggleFocusMode)
                }
                .keyboardShortcut("f", modifiers: [.command, .option])
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
                launchService: launchAtLoginService
            )
            .preferredColorScheme(settingsStore.settings.themePreference.colorScheme)
        }
    }

    @MainActor
    private func handleCommand(_ command: CommandItem) {
        commandStore.perform(command)

        switch command.action {
        case .openDashboard:
            openMainWindow()
        case .openSettings:
            openSettings()
        case .captureClipboard:
            updateClipboardCaptureIfAvailable()
        case .copyStatusReport:
            copyStatusReport()
        case .newNote, .startTimer, .clearInbox, .toggleFocusMode:
            break
        }

        dashboardStore.record(command: command, summary: commandStore.lastActionSummary)
    }

    @MainActor
    private func perform(_ action: CommandAction) {
        guard let command = commandRegistry.command(for: action) else {
            return
        }
        handleCommand(command)
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
    private func updateClipboardCaptureIfAvailable() {
        let text = NSPasteboard.general.string(forType: .string)
        let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedText.isEmpty else {
            commandStore.updateLastActionSummary("Clipboard is empty. Copy text and run again.")
            return
        }

        commandStore.updateLastActionSummary("Captured \(trimmedText.count) clipboard characters.")
    }

    @MainActor
    private func copyStatusReport() {
        let report = """
        CommandKit Status
        Commands: \(commandStore.registry.commands.count)
        Recent: \(commandStore.recentCommands.count)
        Focus: \(commandStore.isFocusModeEnabled ? "active" : "ready")
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        commandStore.updateLastActionSummary("Copied status report to clipboard.")
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
