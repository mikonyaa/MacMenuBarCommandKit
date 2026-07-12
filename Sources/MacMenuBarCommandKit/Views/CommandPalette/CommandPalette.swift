import AppKit
import SwiftUI

public struct CommandPalette: View {
    @ObservedObject private var commandStore: CommandStore
    private let onCommand: (CommandItem) -> Void
    @FocusState private var searchFocused: Bool
    @State private var selectedCommandID: CommandID?
    @State private var previousFirstResponder: NSResponder?
    @State private var previousWindow: NSWindow?

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
            previousWindow = NSApp.keyWindow
            previousFirstResponder = previousWindow?.firstResponder
            selectedCommandID = commandStore.filteredCommands.first?.id
            searchFocused = true
        }
        .onDisappear {
            guard let responder = previousFirstResponder else { return }
            previousWindow?.makeFirstResponder(responder)
        }
        .onChange(of: commandStore.filteredCommands.map(\.id)) { _, ids in
            if let selectedCommandID, ids.contains(selectedCommandID) {
                return
            }
            selectedCommandID = ids.first
        }
        .onMoveCommand(perform: moveSelection)
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
                                .background {
                                    if selectedCommandID == command.id {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.14))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            if isHovering {
                                selectedCommandID = command.id
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
    }

    private func submitTopResult() {
        let commands = commandStore.filteredCommands
        guard let command = commands.first(where: { $0.id == selectedCommandID }) ?? commands.first else {
            return
        }

        onCommand(command)
        commandStore.dismissPalette()
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        let commands = commandStore.filteredCommands
        guard !commands.isEmpty else { return }

        let currentIndex = selectedCommandID.flatMap { id in
            commands.firstIndex { $0.id == id }
        } ?? 0

        switch direction {
        case .up:
            selectedCommandID = commands[max(0, currentIndex - 1)].id
        case .down:
            selectedCommandID = commands[min(commands.count - 1, currentIndex + 1)].id
        default:
            break
        }
    }
}
