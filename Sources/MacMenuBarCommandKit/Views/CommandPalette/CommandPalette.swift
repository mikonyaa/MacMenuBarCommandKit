import SwiftUI

public struct CommandPalette: View {
    @ObservedObject private var commandStore: CommandStore
    private let onCommand: (CommandItem) -> Void

    public init(
        commandStore: CommandStore,
        onCommand: @escaping (CommandItem) -> Void
    ) {
        self.commandStore = commandStore
        self.onCommand = onCommand
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            commandList
        }
        .frame(width: 560, height: 520)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Search commands", text: $commandStore.query)
                .textFieldStyle(.plain)
                .font(.title3)
            Button {
                commandStore.dismissPalette()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close")
        }
        .padding(18)
    }

    @ViewBuilder
    private var commandList: some View {
        let commands = commandStore.filteredCommands
        if commands.isEmpty {
            EmptyStateView(
                title: "No commands found",
                message: "Try another word or add a command to CommandRegistry.",
                systemImage: "command"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(commands) { command in
                        Button {
                            onCommand(command)
                            commandStore.dismissPalette()
                        } label: {
                            CommandRow(command: command)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
    }
}
