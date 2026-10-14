import Combine
import Foundation

@MainActor
public final class CommandStore: ObservableObject {
    @Published public var query: String {
        didSet { reconcilePaletteSelection(registry.filteredCommands(matching: query)) }
    }
    @Published public var isPalettePresented: Bool
    @Published public private(set) var recentCommands: [CommandItem]
    @Published public private(set) var isFocusModeEnabled: Bool
    @Published public private(set) var lastActionSummary: String
    @Published public private(set) var latestResult: CommandExecutionResult?
    // Shared by successive palette views, including a close/reopen transition.
    // Metadata remains owned only by the registry.
    @Published var paletteSelection: CommandID?

    public let registry: CommandRegistry
    private var registryObservation: AnyCancellable?

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
        latestResult = nil
        paletteSelection = nil
        // The registry is the single owner of metadata. Forward its invalidation so
        // a consumer observing only this store also redraws after replacement.
        registryObservation = registry.$commands.dropFirst().sink { [weak self] commands in
            guard let self else { return }
            self.reconcilePaletteSelection(registry.filteredCommands(in: commands, matching: self.query))
            self.objectWillChange.send()
        }
    }

    public var filteredCommands: [CommandItem] {
        registry.filteredCommands(matching: query)
    }

    public var hasActionSummary: Bool {
        latestResult != nil || lastActionSummary != "Ready"
    }

    public func presentPalette() {
        query = ""
        paletteSelection = filteredCommands.first?.id
        isPalettePresented = true
    }

    public func dismissPalette() {
        isPalettePresented = false
    }

    public func updateLastActionSummary(_ summary: String) {
        // Legacy informational summaries carry no success claim.
        latestResult = nil
        lastActionSummary = summary
    }

    /// Publishes a completed app-owned action, including results from an editor.
    public func updateLastActionResult(_ result: CommandExecutionResult) {
        latestResult = result
        lastActionSummary = result.summary
        AccessibilityAnnouncements.post("\(result.succeeded ? "Succeeded" : "Failed"): \(result.summary)")
    }

    @discardableResult
    public func perform(_ command: CommandItem) -> CommandExecutionResult {
        // Views and callers may hold an older value. Resolve by ID at execution
        // time so replaced or removed metadata cannot run a stale action.
        guard let current = registry.command(for: command.id) else {
            let result = CommandExecutionResult.failure("No command metadata exists for \(command.id.rawValue).")
            updateLastActionResult(result)
            return result
        }
        return execute(current)
    }

    private func execute(_ command: CommandItem) -> CommandExecutionResult {
        remember(command)

        guard let handler = registry.handler(for: command.id) else {
            let result = CommandExecutionResult.failure("No handler is registered for \(command.title).")
            updateLastActionResult(result)
            return result
        }

        do {
            let result = try handler(command)
            updateLastActionResult(result)
            return result
        } catch {
            let result = CommandExecutionResult.failure("Could not run \(command.title): \(error.localizedDescription)")
            updateLastActionResult(result)
            return result
        }
    }

    @discardableResult
    public func perform(_ id: CommandID) -> CommandExecutionResult {
        guard let command = registry.command(for: id) else {
            let result = CommandExecutionResult.failure("No command metadata exists for \(id.rawValue).")
            updateLastActionResult(result)
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

    private func reconcilePaletteSelection(_ commands: [CommandItem]) {
        guard isPalettePresented else { return }
        if let paletteSelection, commands.contains(where: { $0.id == paletteSelection }) { return }
        let next = commands.first?.id
        if paletteSelection != next { paletteSelection = next }
    }
}
