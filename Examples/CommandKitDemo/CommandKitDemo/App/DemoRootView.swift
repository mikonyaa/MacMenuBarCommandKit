import MacMenuBarCommandKit
import SwiftUI

struct DemoRootView: View {
    @ObservedObject var commandStore: CommandStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var settingsStore: SettingsStore
    let onCommand: (CommandItem) -> Void
    let reloadDemoContent: () -> Void

    var body: some View {
        CommandPaletteOverlay(commandStore: commandStore, onCommand: onCommand) {
            MainDashboardView(
                commandStore: commandStore,
                dashboardStore: dashboardStore,
                onCommand: onCommand
            )
            .onChange(of: settingsStore.settings.demoDataEnabled) { _, isEnabled in
                if isEnabled {
                    reloadDemoContent()
                } else {
                    dashboardStore.showEmpty()
                }
            }
        }
    }
}
