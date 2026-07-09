import Foundation

public enum CommandCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case productivity
    case ai
    case focus
    case navigation
    case system

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .productivity:
            "Productivity"
        case .ai:
            "AI"
        case .focus:
            "Focus"
        case .navigation:
            "Navigation"
        case .system:
            "System"
        }
    }
}
