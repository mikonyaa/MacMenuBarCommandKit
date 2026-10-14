import AppKit
import SwiftUI

/// NSTextField's field editor consumes arrow/Return keys before SwiftUI's
/// onKeyPress boundary. Its documented delegate routes only reserved palette
/// commands and leaves ordinary editing, paste, and IME input native.
struct PaletteSearchField: NSViewRepresentable {
    @Binding var query: String
    let shouldFocus: Bool
    let isPresented: () -> Bool
    let move: (MoveCommandDirection) -> Void
    let submit: () -> Void
    let dismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: query)
        field.placeholderString = "Search commands"
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 17)
        field.delegate = context.coordinator
        field.setAccessibilityIdentifier("commandkit.palette.search")
        field.setAccessibilityLabel("Search commands")
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != query { field.stringValue = query }
        if shouldFocus, field.currentEditor() == nil {
            let coordinator = context.coordinator
            DispatchQueue.main.async { [weak field, weak coordinator] in
                guard let field, let coordinator, coordinator.parent.isPresented(),
                      let window = field.window else { return }
                window.makeFirstResponder(field)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PaletteSearchField
        init(_ parent: PaletteSearchField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.query = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveDown(_:)):
                parent.move(.down)
            case #selector(NSResponder.moveUp(_:)):
                parent.move(.up)
            case #selector(NSResponder.insertNewline(_:)):
                parent.submit()
            case #selector(NSResponder.cancelOperation(_:)):
                parent.dismiss()
            default:
                return false
            }
            return true
        }
    }
}
