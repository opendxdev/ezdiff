import SwiftUI
import AppKit

// MARK: - Editor Text View (NSViewRepresentable)
// Returns NSScrollView directly — do NOT wrap in a container NSView,
// as Auto Layout inside a container breaks TextKit 2 text rendering.

struct EditorTextView: NSViewRepresentable {
    let file: DiffFile
    let tokens: [HighlightToken]
    let onFocus: (() -> Void)?
    let onScrollChange: ((CGFloat) -> Void)?

    class Coordinator: NSObject, NSTextViewDelegate {
        weak var file: DiffFile?
        var onFocus: (() -> Void)?
        var onScrollChange: ((CGFloat) -> Void)?
        var isUpdatingFromExternal = false
        var scrollObserver: NSObjectProtocol?
        var lastAppliedTokenCount: Int = -1

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromExternal,
                  let textView = notification.object as? NSTextView,
                  let file = file
            else { return }

            let newContent = textView.string
            if newContent != file.content {
                file.content = newContent
                file.markEdited()
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            onFocus?()
        }

        deinit {
            if let obs = scrollObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.usesFontPanel = false

        // Allow horizontal scrolling (no line wrap)
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.size = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true

        textView.delegate = context.coordinator

        let coordinator = context.coordinator
        coordinator.file = file
        coordinator.onFocus = onFocus
        coordinator.onScrollChange = onScrollChange

        // Observe scroll position changes
        scrollView.contentView.postsBoundsChangedNotifications = true
        let scrollObs = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator] notification in
            guard let clipView = notification.object as? NSClipView else { return }
            coordinator?.onScrollChange?(clipView.bounds.origin.y)
        }
        context.coordinator.scrollObserver = scrollObs

        textView.string = file.content

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        let coordinator = context.coordinator

        coordinator.file = file
        coordinator.onFocus = onFocus
        coordinator.onScrollChange = onScrollChange

        if file.content != textView.string {
            coordinator.isUpdatingFromExternal = true
            textView.string = file.content
            coordinator.isUpdatingFromExternal = false
        }

        // Apply syntax highlighting only when tokens change (TextKit 2 safe)
        let tokenCount = tokens.count
        if tokenCount != coordinator.lastAppliedTokenCount, let textStorage = textView.textStorage {
            coordinator.lastAppliedTokenCount = tokenCount
            let source = textView.string
            let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let theme = SyntaxHighlighter.currentTheme
            textStorage.beginEditing()
            textStorage.setAttributes(
                [.font: font, .foregroundColor: NSColor.textColor],
                range: NSRange(location: 0, length: textStorage.length)
            )
            if !tokens.isEmpty {
                SyntaxHighlighter.applyHighlighting(to: textStorage, tokens: tokens, source: source, theme: theme)
            }
            textStorage.endEditing()
        }
    }
}
