import AppKit

@MainActor
enum AccessibilityAnnouncements {
    static func post(_ text: String) {
        guard NSWorkspace.shared.isVoiceOverEnabled else { return }
        NSAccessibility.post(
            element: NSApplication.shared,
            notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.medium.rawValue]
        )
    }
}
