import AppKit
import SwiftUI

public struct CommandKitSettingsView: View {
    @ObservedObject private var settingsStore: SettingsStore
    @StateObject private var launchModel: LaunchAtLoginViewModel
    private let commandItems: [CommandItem]

    public init(
        settingsStore: SettingsStore,
        launchService: LaunchAtLoginService,
        commands: [CommandItem]
    ) {
        self.init(settingsStore: settingsStore, launchController: launchService, commands: commands)
    }

    public init(
        settingsStore: SettingsStore,
        launchController: any LaunchAtLoginControlling,
        commands: [CommandItem]
    ) {
        self.settingsStore = settingsStore
        _launchModel = StateObject(wrappedValue: LaunchAtLoginViewModel(controller: launchController))
        commandItems = commands
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
            launchModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchModel.refresh()
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
                    Text(launchModel.status.title)
                        .foregroundStyle(statusColor)
                        .accessibilityIdentifier("commandkit.login.status")
                }
                launchRecovery
            }

            Section("Behavior") {
                Toggle("Enable demo data", isOn: demoDataBinding)
                    .accessibilityIdentifier("commandkit.settings.demo-data")
                Text("The demo removes only sample entries when disabled. Your session entries and command attempts remain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

    @ViewBuilder
    private var launchRecovery: some View {
        switch launchModel.status {
        case .requiresApproval:
            Text("Registered, awaiting approval. Allow this app in Login Items, then return here.")
                .font(.caption)
            Button("Open Login Items Settings") { launchModel.openLoginItemsSettings() }
                .accessibilityIdentifier("commandkit.login.approval")
            Button("Refresh Status") { launchModel.refresh() }
        case .error(let message):
            Text(message)
                .font(.caption)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("commandkit.login.error")
            Button("Retry Status Check") { launchModel.refresh() }
                .accessibilityIdentifier("commandkit.login.retry")
        case .unsupported:
            Text("Login registration is unavailable for this bundle. Use a signed app installed at a stable path.")
                .font(.caption)
            Button("Refresh Status") { launchModel.refresh() }
        case .enabled, .disabled:
            EmptyView()
        }
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
                ForEach(commandItems.filter { $0.shortcut != nil }) { command in
                    LabeledContent(command.title, value: command.shortcut?.displayValue ?? "")
                }
            }
            Section("Extending") {
                Text("Provide command metadata to the registry and register handlers in your app entry point.")
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
            launchModel.isEnabled
        } set: { value in
            launchModel.setEnabled(value)
        }
    }

    private var demoDataBinding: Binding<Bool> {
        Binding {
            settingsStore.settings.demoDataEnabled
        } set: { value in
            settingsStore.update { $0.demoDataEnabled = value }
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
        switch launchModel.status {
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
