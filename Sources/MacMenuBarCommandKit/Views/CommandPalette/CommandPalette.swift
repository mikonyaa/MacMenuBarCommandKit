import AppKit
import SwiftUI

public struct CommandPalette: View {
    @ObservedObject private var commandStore: CommandStore
    private let onCommand: (CommandItem) -> Void
    @State private var searchFocused = false
    @State private var scrollRevision = 0
    @State private var previousFirstResponder: NSResponder?
    @State private var previousWindow: NSWindow?

    public init(
        commandStore: CommandStore,
        onCommand: @escaping (CommandItem) -> Void
    ) {
        self.commandStore = commandStore
        self.onCommand = onCommand
    }

    private var selectedCommandID: CommandID? {
        get { commandStore.paletteSelection }
        nonmutating set { commandStore.paletteSelection = newValue }
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
        .accessibilityIdentifier("commandkit.palette")
        .onAppear {
            previousWindow = NSApp.keyWindow
            let responder = previousWindow?.firstResponder
            if let editor = responder as? NSTextView, editor.isFieldEditor,
               let owner = editor.delegate as? NSResponder {
                previousFirstResponder = owner
            } else {
                previousFirstResponder = responder
            }
            selectedCommandID = commandStore.filteredCommands.first?.id
            searchFocused = true
        }
        .onDisappear {
            guard let responder = previousFirstResponder,
                  let previousWindow, previousWindow.isKeyWindow,
                  previousWindow.attachedSheet == nil else { return }
            if let view = responder as? NSView, view.window !== previousWindow { return }
            previousWindow.makeFirstResponder(responder)
        }
        .onChange(of: commandStore.isPalettePresented) { _, presented in
            // A quick close/reopen may retain this view during its transition.
            if presented {
                selectedCommandID = commandStore.filteredCommands.first?.id
                searchFocused = true
                scrollRevision += 1
            } else {
                searchFocused = false
            }
        }
        .onChange(of: commandStore.filteredCommands.map(\.id)) { _, ids in
            if let selectedCommandID, ids.contains(selectedCommandID) {
                return
            }
            selectedCommandID = ids.first
            scrollRevision += 1
        }
        .onMoveCommand(perform: moveSelection)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            PaletteSearchField(
                query: $commandStore.query, shouldFocus: searchFocused,
                isPresented: { commandStore.isPalettePresented },
                move: moveSelection, submit: submitTopResult, dismiss: commandStore.dismissPalette
            )
            .frame(height: 24)
            Button {
                commandStore.dismissPalette()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close")
            .accessibilityLabel("Close command palette")
        }
        .padding(18)
    }

    private var commandList: some View {
        let commands = commandStore.filteredCommands
        return ScrollViewReader { proxy in
            ScrollView {
                if commands.isEmpty {
                    EmptyStateView(
                        title: "No commands found",
                        message: "Try another search.", systemImage: "command"
                    )
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(commands) { command in
                            Button {
                                runCommand(command.id)
                            } label: {
                                CommandRow(command: command, isHighlighted: selectedCommandID == command.id)
                            }
                            .buttonStyle(.plain)
                            .id(command.id)
                            .accessibilityIdentifier("commandkit.palette.row.\(command.id.rawValue)")
                            .accessibilityAddTraits(selectedCommandID == command.id ? [.isSelected] : [])
                            .onHover { isHovering in
                                if isHovering { selectedCommandID = command.id }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .onChange(of: scrollRevision) { _, _ in
                scrollToSelection(proxy)
            }
            .onChange(of: commands) { _, _ in
                scrollToSelection(proxy)
            }
            .onChange(of: commandStore.query) { _, _ in
                scrollRevision += 1
            }
        }
    }

    private func scrollToSelection(_ proxy: ScrollViewProxy) {
        guard let selectedCommandID else { return }
        // Keyboard repetition should reveal the current selection immediately.
        // No scroll animation is scheduled, including under Reduce Motion.
        proxy.scrollTo(selectedCommandID, anchor: .center)
    }

    private func submitTopResult() {
        let commands = commandStore.filteredCommands
        guard let command = commands.first(where: { $0.id == selectedCommandID }) ?? commands.first else {
            return
        }

        runCommand(command.id)
    }

    private func runCommand(_ id: CommandID) {
        guard commandStore.isPalettePresented, let current = commandStore.registry.command(for: id) else { return }
        // Close first: a repeated Return cannot dispatch a second action, and the
        // handler may open another window or editor.
        commandStore.dismissPalette()
        onCommand(current)
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
            return
        }
        scrollRevision += 1
        if let selected = commands.first(where: { $0.id == selectedCommandID }),
           let index = commands.firstIndex(where: { $0.id == selected.id }) {
            AccessibilityAnnouncements.post("\(selected.title), selected, \(index + 1) of \(commands.count)")
        }
    }
}
