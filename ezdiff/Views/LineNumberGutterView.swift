import SwiftUI

struct LineNumberGutterView: View {
    let text: String
    let scrollOffset: CGFloat
    let viewportHeight: CGFloat
    let lineLayouts: [LineLayout]

    private let gutterWidth: CGFloat = 44
    private let singleLineHeight: CGFloat = {
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        return ceil(font.ascender - font.descender + font.leading)
    }()

    var body: some View {
        Canvas { context, size in
            // Background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(nsColor: .controlBackgroundColor))
            )

            // Separator line on right edge
            let separatorPath = Path { p in
                p.move(to: CGPoint(x: size.width - 0.5, y: 0))
                p.addLine(to: CGPoint(x: size.width - 0.5, y: size.height))
            }
            context.stroke(separatorPath, with: .color(Color(nsColor: .separatorColor)), lineWidth: 1)

            guard !text.isEmpty, !lineLayouts.isEmpty else { return }

            drawWithLayouts(context: context, size: size)
        }
        .frame(width: gutterWidth)
    }

    // MARK: - Layout-aware drawing

    private func drawWithLayouts(context: GraphicsContext, size: CGSize) {
        // Binary search for first visible line
        let firstIdx = findFirstVisible(scrollOffset: scrollOffset)

        for i in firstIdx..<lineLayouts.count {
            let layout = lineLayouts[i]
            let y = layout.yOffset - scrollOffset

            // Past bottom of viewport — done
            if y > size.height { break }

            // Draw line number centered in the first visual row
            drawLineNumber(layout.lineNumber, at: y, lineHeight: singleLineHeight, context: context)
        }
    }

    /// Binary search for the first layout whose bottom edge is visible.
    private func findFirstVisible(scrollOffset: CGFloat) -> Int {
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

    // MARK: - Drawing helper

    private func drawLineNumber(_ lineNum: Int, at y: CGFloat, lineHeight lh: CGFloat, context: GraphicsContext) {
        let text = Text("\(lineNum)")
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundColor(Color(nsColor: .secondaryLabelColor))

        let resolved = context.resolve(text)
        let textSize = resolved.measure(in: CGSize(width: gutterWidth, height: lh))

        context.draw(
            resolved,
            at: CGPoint(
                x: gutterWidth - textSize.width - 8,
                y: y + (lh - textSize.height) / 2
            ),
            anchor: .topLeading
        )
    }
}
