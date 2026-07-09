import Foundation

public enum CommandModifier: String, CaseIterable, Codable, Sendable {
    case command
    case option
    case shift
    case control

    public var displaySymbol: String {
        switch self {
        case .command:
            "⌘"
        case .option:
            "⌥"
        case .shift:
            "⇧"
        case .control:
            "⌃"
        }
    }
}

public struct CommandShortcut: Hashable, Codable, Sendable {
    public var modifiers: [CommandModifier]
    public var key: String

    public init(modifiers: [CommandModifier] = [.command], key: String) {
        self.modifiers = modifiers
        self.key = key
    }

    public var displayValue: String {
        modifiers.map(\.displaySymbol).joined() + key.uppercased()
    }
}
