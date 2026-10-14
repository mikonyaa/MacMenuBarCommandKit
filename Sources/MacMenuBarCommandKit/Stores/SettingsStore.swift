import Foundation

@MainActor
public final class SettingsStore: ObservableObject {
    public enum Key {
        public static let menuBarPresentation = "MacMenuBarCommandKit.menuBarPresentation"
        public static let themePreference = "MacMenuBarCommandKit.themePreference"
        public static let demoDataEnabled = "MacMenuBarCommandKit.demoDataEnabled"
    }

    @Published public private(set) var settings: AppSettings
    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "MacMenuBarCommandKit.") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
        settings = Self.load(from: defaults, keyPrefix: keyPrefix)
    }

    public func update(_ mutate: (inout AppSettings) -> Void) {
        var next = settings
        mutate(&next)
        settings = next
        persist(next)
    }

    public func reset() {
        settings = .defaults
        persist(.defaults)
    }

    private func persist(_ settings: AppSettings) {
        defaults.set(settings.menuBarPresentation.rawValue, forKey: keyPrefix + "menuBarPresentation")
        defaults.set(settings.themePreference.rawValue, forKey: keyPrefix + "themePreference")
        defaults.set(settings.demoDataEnabled, forKey: keyPrefix + "demoDataEnabled")
    }

    private static func load(from defaults: UserDefaults, keyPrefix: String) -> AppSettings {
        let menuValue = defaults.string(forKey: keyPrefix + "menuBarPresentation")
        let themeValue = defaults.string(forKey: keyPrefix + "themePreference")

        return AppSettings(
            menuBarPresentation: menuValue.flatMap(MenuBarPresentation.init(rawValue:)) ?? .balanced,
            themePreference: themeValue.flatMap(AppThemePreference.init(rawValue:)) ?? .system,
            demoDataEnabled: defaults.object(forKey: keyPrefix + "demoDataEnabled") as? Bool ?? true
        )
    }
}
