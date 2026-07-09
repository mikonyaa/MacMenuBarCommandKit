import Foundation

@MainActor
public final class CommandRegistry: ObservableObject {
    public typealias Handler = @MainActor (CommandItem) -> Void

    @Published public private(set) var commands: [CommandItem]
    private var handlers: [CommandAction: Handler]

    public init(commands: [CommandItem] = CommandItem.demoCommands) {
        self.commands = commands
        handlers = [:]
    }

    public func replaceCommands(_ commands: [CommandItem]) {
        self.commands = commands
    }

    public func register(_ action: CommandAction, handler: @escaping Handler) {
        handlers[action] = handler
    }

    public func handler(for action: CommandAction) -> Handler? {
        handlers[action]
    }

    public func command(for action: CommandAction) -> CommandItem? {
        commands.first { $0.action == action }
    }

    public func filteredCommands(matching query: String) -> [CommandItem] {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        guard !normalizedQuery.isEmpty else {
            return commands
        }

        let tokens = normalizedQuery.split(separator: " ").map(String.init)
        return commands.filter { command in
            tokens.allSatisfy { command.searchableText.contains($0) }
        }
    }
}
