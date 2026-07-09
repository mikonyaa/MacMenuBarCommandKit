import AppKit
import SwiftUI

public struct GrabScrollView<Content: View>: View {
    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let content: Content

    @State private var scrollView: NSScrollView?
    @State private var lastTranslation: CGSize = .zero

    public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    public var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
                .background(ScrollViewResolver(scrollView: $scrollView))
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    scroll(by: value.translation)
                }
                .onEnded { _ in
                    lastTranslation = .zero
                }
        )
    }

    private func scroll(by translation: CGSize) {
        guard let scrollView else {
            return
        }

        let delta = CGSize(
            width: translation.width - lastTranslation.width,
            height: translation.height - lastTranslation.height
        )
        lastTranslation = translation

        let clipView = scrollView.contentView
        var origin = clipView.bounds.origin

        if axes.contains(.horizontal) {
            origin.x -= delta.width
        }
        if axes.contains(.vertical) {
            origin.y -= delta.height
        }

        let documentSize = scrollView.documentView?.bounds.size ?? .zero
        let visibleSize = clipView.bounds.size
        origin.x = min(max(0, origin.x), max(0, documentSize.width - visibleSize.width))
        origin.y = min(max(0, origin.y), max(0, documentSize.height - visibleSize.height))

        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
    }
}

private struct ScrollViewResolver: NSViewRepresentable {
    @Binding var scrollView: NSScrollView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            scrollView = view.firstSuperview(of: NSScrollView.self)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            scrollView = nsView.firstSuperview(of: NSScrollView.self)
        }
    }
}

private extension NSView {
    func firstSuperview<T: NSView>(of type: T.Type) -> T? {
        var candidate = superview
        while let view = candidate {
            if let typedView = view as? T {
                return typedView
            }
            candidate = view.superview
        }
        return nil
    }
}
