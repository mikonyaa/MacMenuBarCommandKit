import AppKit
import MacMenuBarCommandKit

@MainActor
struct DemoLaunchConfiguration {
    let defaults: UserDefaults
    let clipboard: any DemoClipboard
    let timerDuration: TimeInterval
    let testCommandCount: Int?
    let verifyOutput: String?
    let captureDirectory: String?
    let captureSurface: String?
    let captureCommit: String
    let loginController: any LaunchAtLoginControlling
    let arguments: [String]

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.arguments = arguments
        let suite = Self.value("--test-suite", in: arguments)
        let isolated = suite?.hasPrefix("CommandKitTests.") == true
        defaults = isolated ? UserDefaults(suiteName: suite!)! : .standard
        clipboard = PasteboardClipboard(pasteboard: isolated ? NSPasteboard(name: .init(suite! + ".clipboard")) : .general)
        if isolated && arguments.contains("--test-demo-data-off") {
            defaults.set(false, forKey: SettingsStore.Key.demoDataEnabled)
        }
        if isolated, let theme = Self.value("--test-theme", in: arguments).flatMap(AppThemePreference.init(rawValue:)) {
            defaults.set(theme.rawValue, forKey: SettingsStore.Key.themePreference)
        }
        if isolated, let value = Self.value("--test-menu-presentation", in: arguments).flatMap(MenuBarPresentation.init(rawValue:)) {
            defaults.set(value.rawValue, forKey: SettingsStore.Key.menuBarPresentation)
        }
        let duration = Self.value("--test-timer-seconds", in: arguments).flatMap(Double.init)
        timerDuration = isolated && (duration ?? 0) > 0 && (duration ?? 0) <= 60 ? duration! : 25 * 60
        let count = Self.value("--test-command-count", in: arguments).flatMap(Int.init)
        testCommandCount = isolated && count == 100 ? count : nil
        verifyOutput = isolated ? Self.value("--verify-output", in: arguments) : nil
        captureDirectory = isolated ? Self.value("--capture-directory", in: arguments) : nil
        captureSurface = isolated ? Self.value("--capture-surface", in: arguments) : nil
        captureCommit = Self.value("--capture-commit", in: arguments) ?? "unrecorded"
        if isolated, let status = Self.value("--test-login-status", in: arguments) {
            let error = LaunchAtLoginStatus.error("Test registration denied. Retry after checking the bundle.")
            loginController = PreviewLoginController(status: status == "approval" ? .requiresApproval : error)
        } else {
            loginController = LaunchAtLoginService()
        }
    }

    private static func value(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
}

@MainActor
private final class PreviewLoginController: LaunchAtLoginControlling {
    private(set) var status: LaunchAtLoginStatus
    var isEnabled: Bool { status == .enabled }
    init(status: LaunchAtLoginStatus) { self.status = status }
    func refresh() {}
    func setEnabled(_ enabled: Bool) { status = enabled ? .enabled : .disabled }
    func openLoginItemsSettings() { status = .disabled }
}
