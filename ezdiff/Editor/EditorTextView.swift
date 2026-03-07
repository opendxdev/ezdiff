import SwiftUI
import AppKit

// MARK: - Line Number Ruler View

class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.ruleThickness = 44
        self.clientView = textView

        NotificationCenter.default.addObserver(
            self, selector: #selector(needsRedisplay),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(needsRedisplay),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func needsRedisplay() {
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView, let scrollView = scrollView else { return }

        // Background
        NSColor.controlBackgroundColor.setFill()
        rect.fill()

        // Separator line
        NSColor.separatorColor.setStroke()
        NSBezierPath.strokeLine(
            from: NSPoint(x: ruleThickness - 0.5, y: rect.minY),
            to: NSPoint(x: ruleThickness - 0.5, y: rect.maxY)
        )

        let text = textView.string
        guard !text.isEmpty else { return }

        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let visibleRect = scrollView.contentView.bounds
        let textInset = textView.textContainerInset

        let numAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        // Try TextKit 1 first, fall back to font-metric calculation
        if let layoutManager = textView.layoutManager, let container = textView.textContainer {
            let nsString = text as NSString
            let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
            let visibleCharRange = layoutManager.characterRange(
                forGlyphRange: visibleGlyphRange, actualGlyphRange: nil
            )

            var lineNumber = 1
            if visibleCharRange.location > 0 {
                lineNumber = nsString.substring(to: visibleCharRange.location)
                    .components(separatedBy: "\n").count
            }

            var index = visibleCharRange.location
            while index < min(NSMaxRange(visibleCharRange), nsString.length) {
                let lineRange = nsString.lineRange(for: NSRange(location: index, length: 0))
                let glyphRange = layoutManager.glyphRange(
                    forCharacterRange: lineRange, actualCharacterRange: nil
                )
                var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
                lineRect.origin.y += textInset.height - visibleRect.origin.y

                let numStr = "\(lineNumber)" as NSString
                let strSize = numStr.size(withAttributes: numAttrs)
                numStr.draw(
                    at: NSPoint(
                        x: ruleThickness - strSize.width - 8,
                        y: lineRect.origin.y + (lineRect.height - strSize.height) / 2
                    ),
                    withAttributes: numAttrs
                )

                lineNumber += 1
                let next = NSMaxRange(lineRange)
                if next <= index { break }
                index = next
            }
        } else {
            // TextKit 2 fallback: use font metrics
            let lineHeight = ceil(font.ascender - font.descender + font.leading)
            let totalLines = text.components(separatedBy: "\n").count
            let firstVisible = max(0, Int((visibleRect.origin.y - textInset.height) / lineHeight))
            let lastVisible = Int((visibleRect.origin.y + visibleRect.height - textInset.height) / lineHeight) + 1

            for lineIdx in firstVisible..<min(totalLines, lastVisible + 1) {
                let lineNum = lineIdx + 1
                let y = CGFloat(lineIdx) * lineHeight + textInset.height - visibleRect.origin.y
                let numStr = "\(lineNum)" as NSString
                let strSize = numStr.size(withAttributes: numAttrs)
                numStr.draw(
                    at: NSPoint(
                        x: ruleThickness - strSize.width - 8,
                        y: y + (lineHeight - strSize.height) / 2
                    ),
                    withAttributes: numAttrs
                )
            }
        }
    }
}

// MARK: - Editor Text View (NSViewRepresentable)

struct EditorTextView: NSViewRepresentable {
    let file: DiffFile
    let diffLines: [DiffLine]
    let tokens: [HighlightToken]
    let side: PaneSide
    let syncCoordinator: SyncScrollCoordinator
    let onFocus: (() -> Void)?

    class Coordinator: NSObject, NSTextViewDelegate {
        var textView: NSTextView?
        var scrollView: NSScrollView?
        var rulerView: LineNumberRulerView?
        weak var syncCoordinator: SyncScrollCoordinator?
        var side: PaneSide = .left
        weak var file: DiffFile?
        var onFocus: (() -> Void)?
        var isUpdatingFromExternal = false
        var lastKnownContent: String = ""

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromExternal,
                  let textView = notification.object as? NSTextView,
                  let file = file
            else { return }

            let newContent = textView.string
            lastKnownContent = newContent
            if newContent != file.content {
                file.content = newContent
                file.markEdited()
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            onFocus?()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure for code editing (no wrapping)
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

        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.backgroundColor = .textBackgroundColor
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.usesFontPanel = false
        textView.delegate = context.coordinator

        // Line number ruler
        let ruler = LineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = ruler
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.rulerView = ruler
        context.coordinator.syncCoordinator = syncCoordinator
        context.coordinator.side = side
        context.coordinator.file = file
        context.coordinator.onFocus = onFocus
        context.coordinator.lastKnownContent = file.content

        textView.string = file.content

        syncCoordinator.register(scrollView: scrollView, side: side)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        let coordinator = context.coordinator

        coordinator.file = file
        coordinator.onFocus = onFocus

        // Check if text changed externally (file load, not user edit)
        if file.content != coordinator.lastKnownContent {
            coordinator.isUpdatingFromExternal = true

            let savedPosition = scrollView.contentView.bounds.origin
            textView.string = file.content
            coordinator.lastKnownContent = file.content

            scrollView.contentView.scroll(to: savedPosition)
            scrollView.reflectScrolledClipView(scrollView.contentView)

            coordinator.isUpdatingFromExternal = false
        }

        // Apply highlighting
        applyHighlighting(to: textView)
        coordinator.rulerView?.needsDisplay = true
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        coordinator.syncCoordinator?.unregister(side: coordinator.side)
    }

    // MARK: - Highlighting

    private func applyHighlighting(to textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        let currentText = textView.string
        let length = (currentText as NSString).length
        guard length > 0 else { return }
        let fullRange = NSRange(location: 0, length: length)

        // Resolve theme based on text view's actual appearance
        let isDark = textView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let baseTextColor = textView.textColor ?? (isDark ? .white : .black)
        let theme = isDark ? SyntaxHighlighter.darkTheme : SyntaxHighlighter.lightTheme

        // Use TextKit 1 layout manager temporary attributes if available,
        // otherwise fall back to text storage (TextKit 2)
        if let layoutManager = textView.layoutManager {
            // TextKit 1 path: use temporary attributes (display-only, don't modify storage)
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: fullRange)
            layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)

            // Apply syntax highlighting
            if currentText == file.content && !tokens.isEmpty {
                for token in tokens {
                    let nsRange = NSRange(token.range, in: currentText)
                    guard nsRange.location != NSNotFound,
                          nsRange.location + nsRange.length <= length
                    else { continue }

                    let color = theme.color(for: token.type)
                    layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: nsRange)

                    if let bgColor = theme.backgroundColor(for: token.type) {
                        layoutManager.addTemporaryAttribute(.backgroundColor, value: bgColor, forCharacterRange: nsRange)
                    }
                }
            }

            // Apply diff highlighting via temporary attributes
            applyDiffHighlightingTempAttrs(layoutManager: layoutManager, text: currentText)
        } else {
            // TextKit 2 path: use text storage with proper begin/end editing
            textStorage.beginEditing()

            textStorage.addAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: baseTextColor
            ], range: fullRange)
            textStorage.removeAttribute(.backgroundColor, range: fullRange)

            if currentText == file.content && !tokens.isEmpty {
                for token in tokens {
                    let nsRange = NSRange(token.range, in: currentText)
                    guard nsRange.location != NSNotFound,
                          nsRange.location + nsRange.length <= length
                    else { continue }

                    let color = theme.color(for: token.type)
                    textStorage.addAttribute(.foregroundColor, value: color, range: nsRange)

                    if token.type == .keyword {
                        textStorage.addAttribute(
                            .font,
                            value: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
                            range: nsRange
                        )
                    }

                    if let bgColor = theme.backgroundColor(for: token.type) {
                        textStorage.addAttribute(.backgroundColor, value: bgColor, range: nsRange)
                    }
                }
            }

            applyDiffHighlighting(to: textStorage, text: currentText)

            textStorage.endEditing()
        }

        textView.needsDisplay = true
    }

    private func applyDiffHighlightingTempAttrs(layoutManager: NSLayoutManager, text: String) {
        var lineMap: [Int: DiffLine] = [:]
        for diffLine in diffLines {
            let lineNum: Int? = side == .left ? diffLine.lineNumberLeft : diffLine.lineNumberRight
            if let num = lineNum {
                lineMap[num] = diffLine
            }
        }

        guard !lineMap.isEmpty else { return }

        let totalLength = (text as NSString).length
        let lines = text.components(separatedBy: "\n")
        var charOffset = 0
        for (i, line) in lines.enumerated() {
            let lineNum = i + 1
            let lineLength = (line as NSString).length
            guard charOffset + lineLength <= totalLength else { break }
            let lineRange = NSRange(location: charOffset, length: lineLength)

            if let diffLine = lineMap[lineNum] {
                let bgColor = DiffHighlighter.lineBackgroundColor(for: diffLine.type)
                if bgColor != .clear {
                    layoutManager.addTemporaryAttribute(.backgroundColor, value: bgColor, forCharacterRange: lineRange)
                }

                if diffLine.type == .modified && !diffLine.words.isEmpty {
                    var wordOffset = charOffset
                    for word in diffLine.words {
                        let wordLen = (word.text as NSString).length
                        if wordLen > 0 && wordOffset + wordLen <= charOffset + lineLength {
                            let wordRange = NSRange(location: wordOffset, length: wordLen)
                            let wordBg = DiffHighlighter.wordBackgroundColor(for: word.type)
                            if wordBg != .clear {
                                layoutManager.addTemporaryAttribute(.backgroundColor, value: wordBg, forCharacterRange: wordRange)
                            }
                        }
                        wordOffset += wordLen
                    }
                }
            }

            charOffset += lineLength
            if i < lines.count - 1 {
                charOffset += 1
            }
        }
    }

    private func applyDiffHighlighting(to textStorage: NSMutableAttributedString, text: String) {
        var lineMap: [Int: DiffLine] = [:]
        for diffLine in diffLines {
            let lineNum: Int? = side == .left ? diffLine.lineNumberLeft : diffLine.lineNumberRight
            if let num = lineNum {
                lineMap[num] = diffLine
            }
        }

        guard !lineMap.isEmpty else { return }

        let totalLength = (text as NSString).length
        let lines = text.components(separatedBy: "\n")
        var charOffset = 0
        for (i, line) in lines.enumerated() {
            let lineNum = i + 1
            let lineLength = (line as NSString).length
            guard charOffset + lineLength <= totalLength else { break }
            let lineRange = NSRange(location: charOffset, length: lineLength)

            if let diffLine = lineMap[lineNum] {
                DiffHighlighter.applyLineHighlight(
                    to: textStorage, range: lineRange, lineType: diffLine.type
                )

                if diffLine.type == .modified && !diffLine.words.isEmpty {
                    var wordOffset = charOffset
                    for word in diffLine.words {
                        let wordLen = (word.text as NSString).length
                        if wordLen > 0 && wordOffset + wordLen <= charOffset + lineLength {
                            let wordRange = NSRange(location: wordOffset, length: wordLen)
                            DiffHighlighter.applyWordHighlight(
                                to: textStorage, range: wordRange, wordType: word.type
                            )
                        }
                        wordOffset += wordLen
                    }
                }
            }

            charOffset += lineLength
            if i < lines.count - 1 {
                charOffset += 1
            }
        }
    }
}
