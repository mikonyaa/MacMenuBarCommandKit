import Foundation

public enum CommandAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case newNote
    case startTimer
    case summarizeClipboard
    case openDashboard
    case toggleFocusMode
    case openSettings

    public var id: String { rawValue }
}
