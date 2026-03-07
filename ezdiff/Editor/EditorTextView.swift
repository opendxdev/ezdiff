import SwiftUI
import AppKit

// MARK: - Line Number Gutter View

class LineNumberGutterView: NSView {
    weak var scrollView: NSScrollView?
    private var contentString: String = ""
    private let gutterWidth: CGFloat = 44

    private let numAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.secondaryLabelColor
    ]

    override var isFlipped: Bool { true }

    func update(text: String) {
        contentString = text
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()

        // Separator line on the right edge
        NSColor.separatorColor.setStroke()
        NSBezierPath.strokeLine(
            from: NSPoint(x: bounds.width - 0.5, y: dirtyRect.minY),
            to: NSPoint(x: bounds.width - 0.5, y: dirtyRect.maxY)
        )

        guard !contentString.isEmpty, let scrollView = scrollView else { return }

        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let textInsetHeight: CGFloat = 4
        let visibleRect = scrollView.contentView.bounds
        let totalLines = contentString.components(separatedBy: "\n").count
        let firstVisible = max(0, Int((visibleRect.origin.y - textInsetHeight) / lineHeight))
        let lastVisible = Int((visibleRect.origin.y + visibleRect.height - textInsetHeight) / lineHeight) + 1

        for lineIdx in firstVisible..<min(totalLines, lastVisible + 1) {
            let lineNum = lineIdx + 1
            let y = CGFloat(lineIdx) * lineHeight + textInsetHeight - visibleRect.origin.y
            let numStr = "\(lineNum)" as NSString
            let strSize = numStr.size(withAttributes: numAttrs)
            numStr.draw(
                at: NSPoint(
                    x: gutterWidth - strSize.width - 8,
                    y: y + (lineHeight - strSize.height) / 2
                ),
                withAttributes: numAttrs
            )
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
        var gutterView: LineNumberGutterView?
        var scrollObserver: NSObjectProtocol?
        var textChangeObserver: NSObjectProtocol?
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
            gutterView?.update(text: newContent)
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
            if let obs = textChangeObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        // Text scroll view
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.isEditable = true
        textView.isSelectable = true
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

        // Line number gutter (separate view, NOT an NSRulerView)
        let gutterWidth: CGFloat = 44
        let gutter = LineNumberGutterView()
        gutter.scrollView = scrollView

        // Layout: gutter on left, scroll view fills remaining space
        container.addSubview(gutter)
        container.addSubview(scrollView)
        gutter.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gutter.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gutter.topAnchor.constraint(equalTo: container.topAnchor),
            gutter.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            gutter.widthAnchor.constraint(equalToConstant: gutterWidth),
            scrollView.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Observe scroll to redraw gutter
        scrollView.contentView.postsBoundsChangedNotifications = true
        let scrollObs = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak gutter] _ in
            gutter?.needsDisplay = true
        }

        // Store references
        context.coordinator.textView = textView
        context.coordinator.gutterView = gutter
        context.coordinator.scrollObserver = scrollObs
        context.coordinator.file = file
        context.coordinator.onFocus = onFocus
        context.coordinator.lastKnownContent = file.content

        // Set initial content
        textView.string = file.content
        gutter.update(text: file.content)

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        let coordinator = context.coordinator

        coordinator.file = file
        coordinator.onFocus = onFocus

        if file.content != coordinator.lastKnownContent {
            coordinator.isUpdatingFromExternal = true
            textView.string = file.content
            coordinator.lastKnownContent = file.content
            coordinator.gutterView?.update(text: file.content)
            coordinator.isUpdatingFromExternal = false
        }
    }
}
