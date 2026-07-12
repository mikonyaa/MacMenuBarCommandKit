import Foundation

public struct CommandItem: Identifiable, Hashable, Codable, Sendable {
    public var id: CommandID
    public var title: String
    public var subtitle: String
    public var systemImage: String
    public var category: CommandCategory
    public var shortcut: CommandShortcut?

    public init(
        id: CommandID,
        title: String,
        subtitle: String,
        systemImage: String,
        category: CommandCategory,
        shortcut: CommandShortcut? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.category = category
        self.shortcut = shortcut
    }

    public var searchableText: String {
        [
            title,
            subtitle,
            category.title,
            shortcut?.displayValue ?? "",
            id.rawValue
        ]
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }
}
