import AppKit

enum TextViewConfigurator {

    static let editorFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    /// Configures the NSTextView inside a scrollable text view for code editing.
    /// Returns the configured NSTextView for further use.
    @discardableResult
    static func configure(_ scrollView: NSScrollView) -> NSTextView {
        let textView = scrollView.documentView as! NSTextView

        textView.font = editorFont
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.allowsUndo = true

        // Disable all auto-corrections
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

        return textView
    }
}
