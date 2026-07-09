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

    public func presentPalette() {
        query = ""
        isPalettePresented = true
    }

    public func dismissPalette() {
        isPalettePresented = false
    }

    public func perform(_ command: CommandItem) {
        remember(command)

        if let handler = registry.handler(for: command.action) {
            handler(command)
            return
        }

        applyDefaultSideEffect(for: command)
    }

    public func perform(_ action: CommandAction) {
        guard let command = registry.command(for: action) else {
            return
        }
        perform(command)
    }

    private func remember(_ command: CommandItem) {
        recentCommands.removeAll { $0.id == command.id }
        recentCommands.insert(command, at: 0)
        if recentCommands.count > 5 {
            recentCommands.removeLast(recentCommands.count - 5)
        }
    }

    private func applyDefaultSideEffect(for command: CommandItem) {
        switch command.action {
        case .newNote:
            lastActionSummary = "Created a local demo note."
        case .startTimer:
            lastActionSummary = "Started a 25-minute focus timer."
        case .summarizeClipboard:
            lastActionSummary = "Prepared clipboard text for summary."
        case .openDashboard:
            lastActionSummary = "Opened the main dashboard."
        case .toggleFocusMode:
            isFocusModeEnabled.toggle()
            lastActionSummary = isFocusModeEnabled ? "Focus mode enabled." : "Focus mode disabled."
        case .openSettings:
            lastActionSummary = "Opened Settings."
        }
    }
}
