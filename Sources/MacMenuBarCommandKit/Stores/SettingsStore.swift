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

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = Self.load(from: defaults)
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
        defaults.set(settings.menuBarPresentation.rawValue, forKey: Key.menuBarPresentation)
        defaults.set(settings.themePreference.rawValue, forKey: Key.themePreference)
        defaults.set(settings.demoDataEnabled, forKey: Key.demoDataEnabled)
    }

    private static func load(from defaults: UserDefaults) -> AppSettings {
        let menuValue = defaults.string(forKey: Key.menuBarPresentation)
        let themeValue = defaults.string(forKey: Key.themePreference)

        return AppSettings(
            menuBarPresentation: menuValue.flatMap(MenuBarPresentation.init(rawValue:)) ?? .balanced,
            themePreference: themeValue.flatMap(AppThemePreference.init(rawValue:)) ?? .system,
            demoDataEnabled: defaults.object(forKey: Key.demoDataEnabled) as? Bool ?? true
        )
    }
}
