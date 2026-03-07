import AppKit

struct LineLayout: Equatable {
    let lineNumber: Int
    let yOffset: CGFloat
    let height: CGFloat
}

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

    /// Toggles word wrap on/off for the text view.
    static func setWordWrap(_ enabled: Bool, scrollView: NSScrollView, textView: NSTextView) {
        if enabled {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.size.width = scrollView.contentSize.width
            textView.maxSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            scrollView.hasHorizontalScroller = false
        } else {
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
        }
    }

    /// Computes visual line layouts for line number gutter alignment.
    /// Uses NSString.boundingRect to calculate how many visual rows each logical line occupies.
    static func computeLineLayouts(text: String, containerWidth: CGFloat, font: NSFont, textInset: CGFloat) -> [LineLayout] {
        guard !text.isEmpty, containerWidth > 0 else { return [] }

        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let nsText = text as NSString
        // Account for text container inset (left + right)
        let wrapWidth = max(containerWidth - textInset * 2, 50)
        let constraintSize = CGSize(width: wrapWidth, height: .greatestFiniteMagnitude)
        let singleLineHeight = ceil(font.ascender - font.descender + font.leading)

        var layouts: [LineLayout] = []
        var lineStart = 0
        var lineNumber = 1
        var yOffset: CGFloat = textInset // start after top inset

        while lineStart <= nsText.length {
            let lineRange: NSRange
            if lineStart == nsText.length {
                // Empty trailing line after final newline
                layouts.append(LineLayout(lineNumber: lineNumber, yOffset: yOffset, height: singleLineHeight))
                break
            } else {
                lineRange = nsText.lineRange(for: NSRange(location: lineStart, length: 0))
            }

            // Measure the visual height of this logical line when wrapped
            let lineStr = nsText.substring(with: lineRange) as NSString
            let boundingRect = lineStr.boundingRect(
                with: constraintSize,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs
            )
            let lineHeight = max(ceil(boundingRect.height), singleLineHeight)

            layouts.append(LineLayout(lineNumber: lineNumber, yOffset: yOffset, height: lineHeight))

            yOffset += lineHeight
            lineNumber += 1
            lineStart = NSMaxRange(lineRange)
        }

        return layouts
    }
}
