import MacMenuBarCommandKit
import SwiftUI

struct DemoRootView: View {
    @ObservedObject var commandStore: CommandStore
    @ObservedObject var dashboardStore: DashboardStore
    @ObservedObject var settingsStore: SettingsStore
    let onCommand: (CommandItem) -> Void

    var body: some View {
        MainDashboardView(
            commandStore: commandStore,
            dashboardStore: dashboardStore,
            onCommand: onCommand
        )
        .onChange(of: settingsStore.settings.demoDataEnabled) { _, isEnabled in
            if isEnabled {
                dashboardStore.loadDemoContent()
            } else {
                dashboardStore.showEmpty()
            }
        }
    }
}
