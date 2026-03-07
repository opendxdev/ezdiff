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

        NSColor.controlBackgroundColor.setFill()
        rect.fill()

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
        var rulerView: LineNumberRulerView?
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

        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator

        // No-wrap configuration
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

        // Line number ruler
        let ruler = LineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = ruler
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.rulerView = ruler
        context.coordinator.file = file
        context.coordinator.lastKnownContent = file.content

        textView.string = file.content

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        let coordinator = context.coordinator

        coordinator.file = file
        coordinator.onFocus = onFocus

        if file.content != coordinator.lastKnownContent {
            coordinator.isUpdatingFromExternal = true
            textView.string = file.content
            coordinator.lastKnownContent = file.content
            coordinator.isUpdatingFromExternal = false
        }

        coordinator.rulerView?.needsDisplay = true
    }
}
