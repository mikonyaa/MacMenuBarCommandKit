import AppKit
import Foundation

struct DemoInboxEntry: Identifiable, Equatable {
    enum Kind: String { case note, clipboard }
    let id: UUID
    let kind: Kind
    let text: String
    let isSample: Bool

    init(kind: Kind, text: String, isSample: Bool = false, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.text = text
        self.isSample = isSample
    }

    var title: String {
        (isSample ? "Sample · " : "") + (kind == .note ? "Note" : "Clipboard")
    }
}

@MainActor
final class DemoInbox: ObservableObject {
    static let maximumEntries = 50
    static let maximumTextBytes = 16_384
    @Published private(set) var entries: [DemoInboxEntry] = []
    @Published private(set) var canUndoClear = false
    private var clearedEntries: [DemoInboxEntry] = []

    @discardableResult
    func add(_ text: String, kind: DemoInboxEntry.Kind) throws -> DemoInboxEntry {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DemoCommandError.emptyText
        }
        guard text.utf8.count <= Self.maximumTextBytes else { throw DemoCommandError.textTooLarge }
        guard entries.count < Self.maximumEntries else { throw DemoCommandError.inboxFull }
        invalidateUndo()
        let entry = DemoInboxEntry(kind: kind, text: text)
        entries.insert(entry, at: 0)
        return entry
    }

    func setDemoDataEnabled(_ enabled: Bool) {
        invalidateUndo()
        entries.removeAll { $0.isSample }
        if enabled {
            let samples = [
                DemoInboxEntry(kind: .note, text: "A sample note. Create your own with New Note.", isSample: true),
                DemoInboxEntry(kind: .clipboard, text: "Sample clipboard text\nCaptured only when you run Capture Clipboard.", isSample: true)
            ]
            entries.append(contentsOf: samples.prefix(Self.maximumEntries - entries.count))
        }
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard entries.contains(where: { $0.id == id }) else { return false }
        invalidateUndo()
        entries.removeAll { $0.id == id }
        return true
    }

    @discardableResult
    func clear() -> Int {
        guard !entries.isEmpty else { return 0 }
        clearedEntries = entries
        entries = []
        canUndoClear = true
        return clearedEntries.count
    }

    @discardableResult
    func undoClear() -> Bool {
        guard canUndoClear else { return false }
        entries = clearedEntries
        invalidateUndo()
        return true
    }

    private func invalidateUndo() {
        clearedEntries = []
        canUndoClear = false
    }
}

@MainActor
protocol DemoClipboard {
    func readText() -> String?
    func writeText(_ text: String) -> Bool
}

@MainActor
struct PasteboardClipboard: DemoClipboard {
    let pasteboard: NSPasteboard

    func readText() -> String? { pasteboard.string(forType: .string) }

    func writeText(_ text: String) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}

enum DemoCommandError: LocalizedError {
    case emptyText
    case emptyClipboard
    case textTooLarge
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .emptyText: "Enter nonempty text before saving."
        case .emptyClipboard: "The clipboard has no nonempty text. Copy text and try again."
        case .textTooLarge: "Text exceeds the 16 KiB UTF-8 limit. Nothing was added."
        case .inboxFull: "The session inbox is full (50 entries). Delete an entry and try again."
        }
    }
}
