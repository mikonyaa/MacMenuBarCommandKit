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
    public var menuBarPresentation: MenuBarPresentation
    public var themePreference: AppThemePreference
    public var demoDataEnabled: Bool

    public init(
        menuBarPresentation: MenuBarPresentation = .balanced,
        themePreference: AppThemePreference = .system,
        demoDataEnabled: Bool = true
    ) {
        self.menuBarPresentation = menuBarPresentation
        self.themePreference = themePreference
        self.demoDataEnabled = demoDataEnabled
    }

    public static let defaults = AppSettings()
}
