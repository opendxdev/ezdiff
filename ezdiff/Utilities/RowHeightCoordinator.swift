import AppKit
import Combine

@MainActor
final class RowHeightCoordinator: ObservableObject {

    @Published private(set) var rowHeights: [CGFloat] = []
    @Published private(set) var generation: Int = 0

    private let appearance = AppearanceManager.shared

    func recompute(
        leftRows: [any DiffRowData],
        rightRows: [any DiffRowData],
        containerWidth: CGFloat,
        wordWrapEnabled: Bool
    ) {
        let count = max(leftRows.count, rightRows.count)
        let singleHeight = appearance.singleLineHeight

        guard count > 0 else {
            rowHeights = []
            generation += 1
            return
        }

        if !wordWrapEnabled {
            // All rows are single-line height — no measurement needed
            rowHeights = [CGFloat](repeating: singleHeight, count: count)
            generation += 1
            return
        }

        // Word wrap ON: measure each row's text, take max of left and right
        let textWidth = max(containerWidth - AppearanceManager.gutterWidth - 1 - 8, 50)
        let font = appearance.codeFont
        let constraintSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]

        var heights = [CGFloat](repeating: singleHeight, count: count)

        for i in 0..<count {
            let leftH: CGFloat
            if i < leftRows.count && !leftRows[i].isPlaceholder && !leftRows[i].text.isEmpty {
                let rect = (leftRows[i].text as NSString).boundingRect(
                    with: constraintSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs
                )
                leftH = max(ceil(rect.height), singleHeight)
            } else {
                leftH = singleHeight
            }

            let rightH: CGFloat
            if i < rightRows.count && !rightRows[i].isPlaceholder && !rightRows[i].text.isEmpty {
                let rect = (rightRows[i].text as NSString).boundingRect(
                    with: constraintSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs
                )
                rightH = max(ceil(rect.height), singleHeight)
            } else {
                rightH = singleHeight
            }

            heights[i] = max(leftH, rightH)
        }

        rowHeights = heights
        generation += 1
    }
}
