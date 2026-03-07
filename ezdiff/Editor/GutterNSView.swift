import AppKit

final class GutterNSView: NSView {

    static let gutterWidth: CGFloat = 44

    var scrollOffset: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    var lineLayouts: [LineLayout] = [] {
        didSet { needsDisplay = true }
    }

    var hasContent: Bool = false {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    private let numberFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    private let singleLineHeight: CGFloat = {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        return ceil(font.ascender - font.descender + font.leading)
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let size = bounds.size

        // Background
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath.fill(bounds)

        // Separator line on right edge
        NSColor.separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: size.width - 0.5, y: 0))
        separatorPath.line(to: NSPoint(x: size.width - 0.5, y: size.height))
        separatorPath.lineWidth = 1
        separatorPath.stroke()

        guard hasContent, !lineLayouts.isEmpty else { return }

        drawLineNumbers(in: size)
    }

    private func drawLineNumbers(in size: CGSize) {
        let firstIdx = findFirstVisible()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        for i in firstIdx..<lineLayouts.count {
            let layout = lineLayouts[i]
            let y = layout.yOffset - scrollOffset

            if y > size.height { break }

            let numStr = NSAttributedString(string: "\(layout.lineNumber)", attributes: attrs)
            let numSize = numStr.size()

            let drawX = Self.gutterWidth - numSize.width - 8
            let drawY = y + (singleLineHeight - numSize.height) / 2

            numStr.draw(at: NSPoint(x: drawX, y: drawY))
        }
    }

    /// Binary search for the first layout whose bottom edge is visible.
    private func findFirstVisible() -> Int {
        var lo = 0
        var hi = lineLayouts.count
        while lo < hi {
            let mid = (lo + hi) / 2
            let layout = lineLayouts[mid]
            if layout.yOffset + layout.height < scrollOffset {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
