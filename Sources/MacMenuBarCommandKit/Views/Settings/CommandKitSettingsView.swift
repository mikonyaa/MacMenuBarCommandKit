import SwiftUI

public struct CommandKitSettingsView: View {
    @ObservedObject private var settingsStore: SettingsStore
    @ObservedObject private var launchService: LaunchAtLoginService

    public init(
        settingsStore: SettingsStore,
        launchService: LaunchAtLoginService
    ) {
        self.settingsStore = settingsStore
        self.launchService = launchService
    }

    public var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            appearance
                .tabItem { Label("Appearance", systemImage: "paintpalette") }
            commands
                .tabItem { Label("Commands", systemImage: "command") }
            about
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 390)
        .scenePadding()
        .onAppear {
            launchService.refresh()
        }
    }

    private var general: some View {
        Form {
            Section("Launch") {
                Toggle(isOn: launchAtLoginBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                        Text("Uses SMAppService and may require approval in System Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Status")
                    Spacer()
                    Text(launchService.status.title)
                        .foregroundStyle(statusColor)
                }
            }

            Section("Behavior") {
                Toggle("Enable demo data", isOn: demoDataBinding)
                Toggle("Enable notifications placeholder", isOn: notificationsBinding)
                LabeledContent("Dock Icon") {
                    Text("Visible by default")
                        .foregroundStyle(.secondary)
                }
                Text("No-Dock accessory mode is documented as a customization because runtime Dock switching affects activation policy and user expectations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var appearance: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: themeBinding) {
                    ForEach(AppThemePreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Menu Bar") {
                Picker("Presentation", selection: presentationBinding) {
                    ForEach(MenuBarPresentation.allCases) { presentation in
                        Text(presentation.title).tag(presentation)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }

    private var commands: some View {
        Form {
            Section("Keyboard") {
                LabeledContent("Command Palette", value: "⌘K")
                LabeledContent("New Note", value: "⌘N")
                LabeledContent("Settings", value: "⌘,")
            }
            Section("Extending") {
                Text("Add metadata in CommandItem.demoCommands or replace the registry with your own list. Register handlers in your app entry point.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading) {
                    Text("MacMenuBarCommandKit")
                        .font(.title2.bold())
                    Text("Reusable menu bar command shell for macOS.")
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            Text("Built for local-first command utilities with native SwiftUI scenes, MenuBarExtra, Settings, and keyboard shortcuts.")
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(24)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            settingsStore.settings.launchAtLogin
        } set: { value in
            settingsStore.update { $0.launchAtLogin = value }
            launchService.setEnabled(value)
        }
    }

    private var demoDataBinding: Binding<Bool> {
        Binding {
            settingsStore.settings.demoDataEnabled
        } set: { value in
            settingsStore.update { $0.demoDataEnabled = value }
        }
    }

    private var notificationsBinding: Binding<Bool> {
        Binding {
            settingsStore.settings.notificationPlaceholderEnabled
        } set: { value in
            settingsStore.update { $0.notificationPlaceholderEnabled = value }
        }
    }

    private var presentationBinding: Binding<MenuBarPresentation> {
        Binding {
            settingsStore.settings.menuBarPresentation
        } set: { value in
            settingsStore.update { $0.menuBarPresentation = value }
        }
    }

    private var themeBinding: Binding<AppThemePreference> {
        Binding {
            settingsStore.settings.themePreference
        } set: { value in
            settingsStore.update { $0.themePreference = value }
        }
    }

    private var statusColor: Color {
        switch launchService.status {
        case .enabled:
            .green
        case .disabled:
            .secondary
        case .requiresApproval:
            .orange
        case .unsupported, .error:
            .red
        }
    }
}
