import AppKit
import MacMenuBarCommandKit
import SwiftUI

@MainActor
private final class ConsumerState: ObservableObject {
    let store: CommandStore
    @Published var executions = 0
    @Published var lastID = "none"

    init() {
        let registry = CommandRegistry(commands: Self.commands(100))
        store = CommandStore(registry: registry)
        for command in registry.commands {
            registry.register(command.id) { [weak self] current in
                self?.executions += 1
                self?.lastID = current.id.rawValue
                return .success("Ran \(current.title)")
            }
        }
    }

    static func commands(_ count: Int) -> [CommandItem] {
        (0..<count).map { index in
            CommandItem(
                id: CommandID(rawValue: "consumer.action.\(index + 1)"),
                title: String(format: "Consumer Action %03d", index + 1),
                subtitle: "Independent app command", systemImage: "command", category: .productivity
            )
        }
    }
}

private struct ConsumerWorkspace: View {
    @ObservedObject var state: ConsumerState
    @ObservedObject var store: CommandStore

    private func perform(_ command: CommandItem) { _ = store.perform(command) }

    var body: some View {
        CommandPaletteOverlay(commandStore: store, onCommand: perform) {
            VStack(spacing: 20) {
                TextField("Previous focus", text: .constant(""))
                    .accessibilityIdentifier("consumer.previous-focus")
                Text("Executions: \(state.executions); ID: \(state.lastID)")
                    .accessibilityIdentifier("consumer.execution")
                Button("Open Palette") { store.presentPalette() }
                HStack {
                    Button("One") { store.registry.replaceCommands(ConsumerState.commands(1)) }
                    Button("Thirty") { store.registry.replaceCommands(ConsumerState.commands(30)) }
                    Button("Empty") { store.registry.replaceCommands([]) }
                    Button("Hundred") { store.registry.replaceCommands(ConsumerState.commands(100)) }
                }
                Text("Commands: \(store.filteredCommands.count)")
                ForEach(Array(store.filteredCommands.prefix(3))) { Text($0.title) }
            }
            .padding(40)
        }
    }
}

@main
private struct IndependentConsumerApp: App {
    @StateObject private var state = ConsumerState()

    var body: some Scene {
        Window("Independent Consumer", id: "consumer") {
            ConsumerWorkspace(state: state, store: state.store)
                .frame(minWidth: 760, minHeight: 680)
        }
    }
}
