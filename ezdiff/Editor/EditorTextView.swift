import SwiftUI
import AppKit

// MARK: - Editor Text View (NSViewRepresentable)
// Returns NSScrollView directly — do NOT wrap in a container NSView,
// as Auto Layout inside a container breaks TextKit 2 text rendering.

struct EditorTextView: NSViewRepresentable {
    let file: DiffFile
    let tokens: [HighlightToken]
    let diffLines: [DiffLine]
    let side: PaneSide
    let wordWrapEnabled: Bool
    let onFocus: (() -> Void)?
    let onScrollChange: ((CGFloat) -> Void)?
    let onLineLayoutChange: (([LineLayout]) -> Void)?
    let onScrollViewReady: ((NSScrollView) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = TextViewConfigurator.configure(scrollView)

        textView.delegate = context.coordinator

        let coordinator = context.coordinator
        coordinator.file = file
        coordinator.onFocus = onFocus
        coordinator.onScrollChange = onScrollChange
        coordinator.onLineLayoutChange = onLineLayoutChange

        // Observe scroll position changes (for line number gutter)
        scrollView.contentView.postsBoundsChangedNotifications = true
        let scrollObs = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator] notification in
            guard let clipView = notification.object as? NSClipView else { return }
            coordinator?.onScrollChange?(clipView.bounds.origin.y)
        }
        coordinator.scrollObserver = scrollObs

        textView.string = file.content

        TextViewConfigurator.setWordWrap(wordWrapEnabled, scrollView: scrollView, textView: textView)

        onScrollViewReady?(scrollView)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        let coordinator = context.coordinator

        coordinator.file = file
        coordinator.onFocus = onFocus
        coordinator.onScrollChange = onScrollChange
        coordinator.onLineLayoutChange = onLineLayoutChange

        if file.content != textView.string {
            coordinator.isUpdatingFromExternal = true
            textView.string = file.content
            coordinator.isUpdatingFromExternal = false
        }

        // Apply word wrap setting
        TextViewConfigurator.setWordWrap(wordWrapEnabled, scrollView: nsView, textView: textView)

        // Apply highlighting only when tokens or diff lines change
        let newState = HighlightState(tokenCount: tokens.count, diffLineCount: diffLines.count)
        if newState != coordinator.lastHighlightState, let textStorage = textView.textStorage {
            coordinator.lastHighlightState = newState
            HighlightApplicator.apply(
                to: textStorage,
                tokens: tokens,
                diffLines: diffLines,
                side: side,
                source: textView.string,
                font: TextViewConfigurator.editorFont
            )
        }

        // Compute and report line layouts for gutter alignment
        if wordWrapEnabled {
            let containerWidth = nsView.contentSize.width
            let layouts = TextViewConfigurator.computeLineLayouts(
                text: textView.string,
                containerWidth: containerWidth,
                font: TextViewConfigurator.editorFont,
                textInset: textView.textContainerInset.width
            )
            coordinator.onLineLayoutChange?(layouts)
        } else {
            coordinator.onLineLayoutChange?([])
        }
    }
}
