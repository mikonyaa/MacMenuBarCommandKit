import MacMenuBarCommandKit
import SwiftUI

struct DemoRootView: View {
    @ObservedObject var commandStore: CommandStore
    @ObservedObject var runtime: DemoCommandRuntime
    let onCommand: (CommandItem) -> Void
    let onOperation: (String, CommandExecutionResult) -> Void

    var body: some View {
        CommandPaletteOverlay(commandStore: commandStore, onCommand: onCommand) {
            HSplitView {
                MainDashboardView(commandStore: commandStore, dashboardStore: runtime.dashboard, onCommand: onCommand)
                    .frame(minWidth: 760)
                DemoInboxPanel(runtime: runtime, onOperation: onOperation)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            }
        }
        .sheet(isPresented: $runtime.isNoteEditorPresented) {
            DemoNoteEditor(runtime: runtime, onOperation: onOperation)
        }
    }
}

private struct DemoNoteEditor: View {
    @ObservedObject var runtime: DemoCommandRuntime
    let onOperation: (String, CommandExecutionResult) -> Void
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New Note").font(.title2.bold())
            Text("Saved text is available in this session until app quit or Clear. Maximum 16 KiB UTF-8.")
                .font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text)
                .focused($focused)
                .accessibilityIdentifier("demo.note.editor")
                .frame(height: 160)
                .border(.separator)
            if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("demo.note.error") }
            HStack {
                Button("Cancel") { runtime.cancelNote() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let result = runtime.saveNote(text)
                    error = result.succeeded ? nil : result.summary
                    onOperation("Save Note", result)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("demo.note.save")
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { focused = true }
    }
}

private struct DemoInboxPanel: View {
    @ObservedObject var runtime: DemoCommandRuntime
    let onOperation: (String, CommandExecutionResult) -> Void
    @State private var selection: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Inbox").font(.title2.bold())
            Text("\(runtime.inbox.entries.count) / 50 entries").accessibilityIdentifier("demo.inbox.count")
            Text("History records: \(runtime.attempts.count)")
                .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("demo.attempt.count")
            Text("Session only · Text is lost on app quit or Clear. Disabling demo data removes only labelled samples.")
                .font(.caption).foregroundStyle(.secondary)
            List(runtime.inbox.entries, selection: $selection) { entry in
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.title).font(.callout.weight(.semibold))
                    Text(entry.text).font(.caption).lineLimit(2).foregroundStyle(.secondary)
                }
                .tag(entry.id)
                .accessibilityIdentifier("demo.inbox.entry.\(entry.id.uuidString)")
            }
            .listStyle(.inset)
            .frame(minHeight: 130)
            if let entry = selectedEntry {
                ScrollView {
                    Text(entry.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("demo.inbox.content")
                }
                .frame(maxHeight: 160)
                HStack {
                    Button("Copy Text") { onOperation("Copy Inbox Entry", runtime.copyEntry(entry.id)) }
                    Button("Delete", role: .destructive) { onOperation("Delete Inbox Entry", runtime.deleteEntry(entry.id)) }
                }
            } else {
                Text(runtime.inbox.entries.isEmpty ? "No entries. Use New Note or Capture Clipboard." : "Select an entry to read, copy, or delete it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("Clear deletes all current entries. Undo Clear remains available until the next inbox change.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Clear Inbox", role: .destructive) { onOperation("Clear Inbox", runtime.clearInbox()) }
                    .accessibilityIdentifier("demo.inbox.clear")
                Button("Undo Clear") { onOperation("Undo Clear", runtime.undoClear()) }.disabled(!runtime.inbox.canUndoClear)
            }
            Divider()
            Label(runtime.timer.summary, systemImage: "timer").font(.headline).accessibilityIdentifier("demo.timer.state")
            Text("\(Int(runtime.timer.completedDuration / 60)) completed minutes this session. Does not change system Focus.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Start Timer") { onOperation("Start Timer", runtime.startTimer()) }
                    .disabled(runtime.timer.state == .running).accessibilityIdentifier("demo.timer.start")
                Button("Cancel Timer") { onOperation("Cancel Timer", runtime.cancelTimer()) }
                    .disabled(runtime.timer.state != .running).accessibilityIdentifier("demo.timer.cancel")
            }
        }
        .padding(18)
        .onChange(of: runtime.inbox.entries.map(\.id)) { _, ids in
            if let selection, !ids.contains(selection) { self.selection = nil }
        }
    }

    private var selectedEntry: DemoInboxEntry? { runtime.inbox.entries.first { $0.id == selection } }
}
