import SwiftUI

public struct CommandPalette: View {
    @ObservedObject private var commandStore: CommandStore
    private let onCommand: (CommandItem) -> Void
    @FocusState private var searchFocused: Bool

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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.separator.opacity(0.55), lineWidth: 1)
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            searchFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Search commands", text: $commandStore.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onSubmit {
                    submitTopResult()
                }
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
            GrabScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(commands) { command in
                        Button {
                            onCommand(command)
                            commandStore.dismissPalette()
                        } label: {
                            CommandRow(command: command)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
    }

    private func submitTopResult() {
        guard let command = commandStore.filteredCommands.first else {
            return
        }

        onCommand(command)
        commandStore.dismissPalette()
    }
}
