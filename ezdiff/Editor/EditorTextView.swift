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
        // Uses throttled callback to cap SwiftUI state updates at 60fps
        scrollView.contentView.postsBoundsChangedNotifications = true
        let scrollObs = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator] notification in
            guard let clipView = notification.object as? NSClipView else { return }
            coordinator?.throttledScrollUpdate(clipView.bounds.origin.y)
        }
        coordinator.scrollObserver = scrollObs

        textView.string = file.content

        TextViewConfigurator.setWordWrap(wordWrapEnabled, scrollView: scrollView, textView: textView)

        onScrollViewReady?(scrollView)

        // Compute initial line layouts after TextKit 2 performs first layout
        let wrapEnabled = wordWrapEnabled
        let textInset = textView.textContainerInset.width
        DispatchQueue.main.async {
            let layouts = TextViewConfigurator.computeLineLayouts(
                text: textView.string,
                containerWidth: scrollView.contentSize.width,
                font: TextViewConfigurator.editorFont,
                textInset: textInset,
                wordWrapEnabled: wrapEnabled
            )
            coordinator.onLineLayoutChange?(layouts)
            coordinator.lastLayoutText = textView.string
            coordinator.lastLayoutContainerWidth = scrollView.contentSize.width
        }

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
            coordinator.lastHighlightState = HighlightState()
            coordinator.lastLayoutText = "" // invalidate layout cache
        }

        // Apply word wrap setting
        TextViewConfigurator.setWordWrap(wordWrapEnabled, scrollView: nsView, textView: textView)

        // Apply highlighting only when tokens or diff lines change
        var highlightApplied = false
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
            highlightApplied = true
        }

        // Recompute line layouts only when text or container width actually changed
        let currentText = textView.string
        let currentWidth = nsView.contentSize.width
        let textChanged = currentText != coordinator.lastLayoutText
        let widthChanged = abs(currentWidth - coordinator.lastLayoutContainerWidth) > 1.0

        if textChanged || widthChanged || highlightApplied {
            coordinator.lastLayoutText = currentText
            coordinator.lastLayoutContainerWidth = currentWidth

            let textInset = textView.textContainerInset.width
            let wrapEnabled = wordWrapEnabled
            DispatchQueue.main.async {
                let layouts = TextViewConfigurator.computeLineLayouts(
                    text: currentText,
                    containerWidth: currentWidth,
                    font: TextViewConfigurator.editorFont,
                    textInset: textInset,
                    wordWrapEnabled: wrapEnabled
                )
                coordinator.onLineLayoutChange?(layouts)
            }
        }
    }
}
