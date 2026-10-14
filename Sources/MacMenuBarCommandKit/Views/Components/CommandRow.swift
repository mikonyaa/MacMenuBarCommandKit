import SwiftUI

public struct CommandRow: View {
    private let command: CommandItem
    private let isHighlighted: Bool
    @State private var isHovering = false

    public init(command: CommandItem, isHighlighted: Bool = false) {
        self.command = command
        self.isHighlighted = isHighlighted
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(command.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text(command.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if let shortcut = command.shortcut {
                Text(shortcut.displayValue)
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isHighlighted || isHovering {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.tint.opacity(isHighlighted ? 0.14 : 0.08))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isHighlighted ? [.isSelected] : [])
    }
}
