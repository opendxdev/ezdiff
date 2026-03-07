import SwiftUI

struct LineNumberGutterView: View {
    let text: String
    let scrollOffset: CGFloat
    let viewportHeight: CGFloat
    let lineLayouts: [LineLayout]

    private let gutterWidth: CGFloat = 44
    private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    private let textInsetHeight: CGFloat = 4

    private var lineHeight: CGFloat {
        ceil(font.ascender - font.descender + font.leading)
    }

    private var totalLines: Int {
        text.isEmpty ? 0 : text.components(separatedBy: "\n").count
    }

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

            guard totalLines > 0 else { return }

            if lineLayouts.isEmpty {
                drawFixedHeight(context: context, size: size)
            } else {
                drawWithLayouts(context: context, size: size)
            }
        }
        .frame(width: gutterWidth)
    }

    // MARK: - Fixed height mode (no word wrap)

    private func drawFixedHeight(context: GraphicsContext, size: CGSize) {
        let lh = lineHeight
        let firstVisible = max(0, Int((scrollOffset - textInsetHeight) / lh))
        let lastVisible = Int((scrollOffset + size.height - textInsetHeight) / lh) + 1

        for lineIdx in firstVisible..<min(totalLines, lastVisible + 1) {
            let lineNum = lineIdx + 1
            let y = CGFloat(lineIdx) * lh + textInsetHeight - scrollOffset

            drawLineNumber(lineNum, at: y, lineHeight: lh, context: context)
        }
    }

    // MARK: - Layout-aware mode (word wrap)

    private func drawWithLayouts(context: GraphicsContext, size: CGSize) {
        for layout in lineLayouts {
            let y = layout.yOffset - scrollOffset

            // Skip lines that are off-screen
            if y + layout.height < 0 { continue }
            if y > size.height { break }

            // Draw line number centered in the first visual row of the wrapped line
            drawLineNumber(layout.lineNumber, at: y, lineHeight: lineHeight, context: context)
        }
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
