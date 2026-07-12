import Foundation

@MainActor
public final class CommandStore: ObservableObject {
    @Published public var query: String
    @Published public var isPalettePresented: Bool
    @Published public private(set) var recentCommands: [CommandItem]
    @Published public private(set) var isFocusModeEnabled: Bool
    @Published public private(set) var lastActionSummary: String

    public let registry: CommandRegistry

    public init(
        registry: CommandRegistry,
        query: String = "",
        recentCommands: [CommandItem] = []
    ) {
        self.registry = registry
        self.query = query
        isPalettePresented = false
        self.recentCommands = recentCommands
        isFocusModeEnabled = false
        lastActionSummary = "Ready"
    }

    public var filteredCommands: [CommandItem] {
        registry.filteredCommands(matching: query)
    }

    public var hasActionSummary: Bool {
        lastActionSummary != "Ready"
    }

    public func presentPalette() {
        query = ""
        isPalettePresented = true
    }

    public func dismissPalette() {
        isPalettePresented = false
    }

    public func updateLastActionSummary(_ summary: String) {
        lastActionSummary = summary
    }

    @discardableResult
    public func perform(_ command: CommandItem) -> CommandExecutionResult {
        remember(command)

        guard let handler = registry.handler(for: command.id) else {
            let result = CommandExecutionResult.failure("No handler is registered for \(command.title).")
            lastActionSummary = result.summary
            return result
        }

        do {
            let result = try handler(command)
            lastActionSummary = result.summary
            return result
        } catch {
            let result = CommandExecutionResult.failure("Could not run \(command.title): \(error.localizedDescription)")
            lastActionSummary = result.summary
            return result
        }
    }

    @discardableResult
    public func perform(_ id: CommandID) -> CommandExecutionResult {
        guard let command = registry.command(for: id) else {
            let result = CommandExecutionResult.failure("No command metadata exists for \(id.rawValue).")
            lastActionSummary = result.summary
            return result
        }
        return perform(command)
    }

    private func remember(_ command: CommandItem) {
        recentCommands.removeAll { $0.id == command.id }
        recentCommands.insert(command, at: 0)
        if recentCommands.count > 5 {
            recentCommands.removeLast(recentCommands.count - 5)
        }
    }

    public func setFocusModeEnabled(_ isEnabled: Bool) {
        isFocusModeEnabled = isEnabled
    }
}
