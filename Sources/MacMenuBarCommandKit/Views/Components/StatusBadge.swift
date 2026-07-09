import SwiftUI

public struct StatusBadge: View {
    private let title: String
    private let systemImage: String
    private let color: Color

    public init(_ title: String, systemImage: String = "circle.fill", color: Color = .green) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}
