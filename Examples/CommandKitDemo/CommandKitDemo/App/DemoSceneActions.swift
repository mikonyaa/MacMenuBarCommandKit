import AppKit
import MacMenuBarCommandKit
import SwiftUI

@MainActor
final class DemoSceneActions: ObservableObject {
    private var windowAction: OpenWindowAction?
    private var settingsAction: OpenSettingsAction?

    func install(window: OpenWindowAction, settings: OpenSettingsAction) {
        windowAction = window
        settingsAction = settings
    }

    func openMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "CommandKit" && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            windowAction?(id: "main")
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func openSettings() {
        settingsAction?()
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct DemoSceneBridge<Content: View>: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    let actions: DemoSceneActions
    @ViewBuilder var content: () -> Content

    var body: some View {
        content().onAppear { actions.install(window: openWindow, settings: openSettings) }
    }
}

struct DemoCommandMenus: Commands {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var registry: CommandRegistry
    @ObservedObject var store: CommandStore
    let actions: DemoSceneActions
    let onCommand: (CommandItem) -> Void

    var body: some Commands {
        CommandGroup(replacing: .newItem) { commandButton(.newNote) }
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { installActions(); actions.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
        }
        CommandMenu("CommandKit") {
            // Navigation exists even for an empty or replaced command catalog.
            Button("Open Window") { installActions(); actions.openMainWindow() }
            Button("Command Palette") {
                installActions()
                actions.openMainWindow()
                store.presentPalette()
            }
            .keyboardShortcut("k", modifiers: .command)
            Divider()
            ForEach(registry.commands.filter { $0.id != .newNote && $0.id != .openSettings }) { command in
                commandButton(command.id)
            }
        }
    }

    private func installActions() { actions.install(window: openWindow, settings: openSettings) }

    @ViewBuilder
    private func commandButton(_ id: CommandID) -> some View {
        if let command = registry.command(for: id) {
            Button(command.title) { installActions(); onCommand(command) }.demoKeyboardShortcut(command.shortcut)
        }
    }
}
