import Foundation

public enum MenuBarPresentation: String, CaseIterable, Codable, Identifiable, Sendable {
    case balanced
    case compact

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .balanced:
            "Balanced"
        case .compact:
            "Compact"
        }
    }
}

public enum AppThemePreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }
}

public struct AppSettings: Hashable, Codable, Sendable {
    public var launchAtLogin: Bool
    public var menuBarPresentation: MenuBarPresentation
    public var themePreference: AppThemePreference
    public var demoDataEnabled: Bool
    public var notificationPlaceholderEnabled: Bool

    public init(
        launchAtLogin: Bool = false,
        menuBarPresentation: MenuBarPresentation = .balanced,
        themePreference: AppThemePreference = .system,
        demoDataEnabled: Bool = true,
        notificationPlaceholderEnabled: Bool = false
    ) {
        self.launchAtLogin = launchAtLogin
        self.menuBarPresentation = menuBarPresentation
        self.themePreference = themePreference
        self.demoDataEnabled = demoDataEnabled
        self.notificationPlaceholderEnabled = notificationPlaceholderEnabled
    }

    public static let defaults = AppSettings()
}
