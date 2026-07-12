/// A stable, app-defined identifier used to connect command metadata to behavior.
public struct CommandID: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }
}

/// The synchronous outcome returned by a registered command handler.
public enum CommandExecutionResult: Equatable, Sendable {
    case success(String)
    case failure(String)

    public var summary: String {
        switch self {
        case .success(let summary), .failure(let summary):
            summary
        }
    }

    public var succeeded: Bool {
        if case .success = self {
            true
        } else {
            false
        }
    }
}
