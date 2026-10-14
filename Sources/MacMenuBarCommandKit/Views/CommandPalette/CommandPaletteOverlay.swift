import SwiftUI

public struct CommandPaletteOverlay<Background: View>: View {
    @ObservedObject private var commandStore: CommandStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let background: Background
    private let onCommand: (CommandItem) -> Void

    public init(
        commandStore: CommandStore,
        onCommand: @escaping (CommandItem) -> Void,
        @ViewBuilder background: () -> Background
    ) {
        self.commandStore = commandStore
        self.onCommand = onCommand
        self.background = background()
    }

    public var body: some View {
        ZStack {
            background
                .disabled(commandStore.isPalettePresented)
                .allowsHitTesting(!commandStore.isPalettePresented)
                .accessibilityHidden(commandStore.isPalettePresented)

            if commandStore.isPalettePresented {
                dimmingLayer
                CommandPalette(commandStore: commandStore, onCommand: onCommand)
                    .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 18)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.985).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.16), value: commandStore.isPalettePresented)
        .onExitCommand {
            if commandStore.isPalettePresented {
                commandStore.dismissPalette()
            }
        }
    }

    private var dimmingLayer: some View {
        Button {
            commandStore.dismissPalette()
        } label: {
            Rectangle()
                .fill(Color.black.opacity(0.34))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss command palette")
        .accessibilityHint("Closes the command palette without running a command.")
        .keyboardShortcut(.cancelAction)
        .contentShape(Rectangle())
        .transition(.opacity)
        .zIndex(1)
    }
}
