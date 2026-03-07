import SwiftUI

struct LineNumberGutterView: View {
    let text: String
    let scrollOffset: CGFloat
    let viewportHeight: CGFloat

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

            let lh = lineHeight
            let firstVisible = max(0, Int((scrollOffset - textInsetHeight) / lh))
            let lastVisible = Int((scrollOffset + size.height - textInsetHeight) / lh) + 1

            for lineIdx in firstVisible..<min(totalLines, lastVisible + 1) {
                let lineNum = lineIdx + 1
                let y = CGFloat(lineIdx) * lh + textInsetHeight - scrollOffset

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
        .frame(width: gutterWidth)
    }
}
