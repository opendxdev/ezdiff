import AppKit
import Combine

@MainActor
final class RowHeightCoordinator: ObservableObject {

    @Published private(set) var rowHeights: [CGFloat] = []
    @Published private(set) var generation: Int = 0

    private let appearance = AppearanceManager.shared

    func recompute(
        leftLines: [DiffLine],
        rightLines: [DiffLine],
        containerWidth: CGFloat,
        wordWrapEnabled: Bool
    ) {
        let count = max(leftLines.count, rightLines.count)
        let singleHeight = appearance.singleLineHeight + Constants.Cell.verticalPadding

        guard count > 0 else {
            rowHeights = []
            generation += 1
            return
        }

        if !wordWrapEnabled {
            rowHeights = [CGFloat](repeating: singleHeight, count: count)
            generation += 1
            return
        }

        let textWidth = max(containerWidth - Constants.Cell.gutterWidth - Constants.Cell.separatorWidth - Constants.Cell.textLeadingMargin - Constants.Cell.textTrailingMargin, 50)
        let font = appearance.codeFont
        let constraintSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]

        var heights = [CGFloat](repeating: singleHeight, count: count)

        for i in 0..<count {
            let leftH: CGFloat
            if i < leftLines.count {
                let line = leftLines[i]
                let isPlaceholder = line.lineNumberLeft == nil
                if !isPlaceholder && !line.text.isEmpty {
                    let rect = (line.text as NSString).boundingRect(
                        with: constraintSize,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attrs
                    )
                    leftH = max(ceil(rect.height), singleHeight)
                } else {
                    leftH = singleHeight
                }
            } else {
                leftH = singleHeight
            }

            let rightH: CGFloat
            if i < rightLines.count {
                let line = rightLines[i]
                let isPlaceholder = line.lineNumberRight == nil
                if !isPlaceholder && !line.text.isEmpty {
                    let rect = (line.text as NSString).boundingRect(
                        with: constraintSize,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attrs
                    )
                    rightH = max(ceil(rect.height), singleHeight)
                } else {
                    rightH = singleHeight
                }
            } else {
                rightH = singleHeight
            }

            heights[i] = max(leftH, rightH)
        }

        rowHeights = heights
        generation += 1
    }

    func recomputeUnified(
        lines: [DiffLine],
        containerWidth: CGFloat,
        wordWrapEnabled: Bool
    ) {
        let count = lines.count
        let singleHeight = appearance.singleLineHeight + Constants.UnifiedCell.verticalPadding

        guard count > 0 else {
            rowHeights = []
            generation += 1
            return
        }

        if !wordWrapEnabled {
            rowHeights = [CGFloat](repeating: singleHeight, count: count)
            generation += 1
            return
        }

        let textWidth = max(
            containerWidth
                - Constants.UnifiedCell.gutterWidth * 2
                - Constants.UnifiedCell.separatorWidth * 2
                - Constants.UnifiedCell.prefixWidth
                - Constants.UnifiedCell.textLeadingMargin
                - Constants.UnifiedCell.textTrailingMargin,
            50
        )
        let font = appearance.codeFont
        let constraintSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]

        var heights = [CGFloat](repeating: singleHeight, count: count)

        for i in 0..<count {
            let line = lines[i]
            if !line.text.isEmpty {
                let rect = (line.text as NSString).boundingRect(
                    with: constraintSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs
                )
                heights[i] = max(ceil(rect.height) + Constants.UnifiedCell.verticalPadding, singleHeight)
            }
        }

        rowHeights = heights
        generation += 1
    }
}
