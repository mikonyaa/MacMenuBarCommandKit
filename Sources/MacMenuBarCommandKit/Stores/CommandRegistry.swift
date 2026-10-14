import Foundation

@MainActor
public final class CommandRegistry: ObservableObject {
    public typealias Handler = @MainActor (CommandItem) throws -> CommandExecutionResult

    @Published public private(set) var commands: [CommandItem]
    private var handlers: [CommandID: Handler]

    public init(commands: [CommandItem] = []) {
        self.commands = commands
        handlers = [:]
    }

    public func replaceCommands(_ commands: [CommandItem]) {
        self.commands = commands
    }

    public func register(_ id: CommandID, handler: @escaping Handler) {
        handlers[id] = handler
    }

    public func handler(for id: CommandID) -> Handler? {
        handlers[id]
    }

    public func command(for id: CommandID) -> CommandItem? {
        commands.first { $0.id == id }
    }

    public func filteredCommands(matching query: String) -> [CommandItem] {
        filteredCommands(in: commands, matching: query)
    }

    func filteredCommands(in commands: [CommandItem], matching query: String) -> [CommandItem] {
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
