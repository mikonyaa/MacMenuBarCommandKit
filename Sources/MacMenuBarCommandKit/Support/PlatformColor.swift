import SwiftUI

public extension ActivityTone {
    var color: Color {
        switch self {
        case .accent:
            .accentColor
        case .success:
            .green
        case .warning:
            .orange
        case .neutral:
            .secondary
        }
    }
}

public extension AppThemePreference {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
