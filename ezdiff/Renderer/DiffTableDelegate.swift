import AppKit

enum RowAction {
    case clicked(Int)
    case doubleClicked(Int)
}

final class DiffTableDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    var rows: [any DiffRowData] = []
    var rowHeights: [CGFloat] = []
    var perLineTokens: [[LineHighlightToken]] = []
    var appearance: AppearanceManager = .shared
    var attributedStringCache = AttributedStringCache()
    var onRowAction: ((RowAction) -> Void)?

    private let defaultRowHeight: CGFloat

    override init() {
        defaultRowHeight = AppearanceManager.shared.singleLineHeight
        super.init()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }

        let cell = tableView.makeView(
            withIdentifier: DiffRowCellView.identifier,
            owner: nil
        ) as? DiffRowCellView ?? DiffRowCellView(frame: .zero)
        cell.identifier = DiffRowCellView.identifier

        let rowData = rows[row]

        // Get per-line tokens for this row (if available)
        let tokens: [LineHighlightToken]
        if let lineNum = rowData.lineNumber, lineNum > 0, lineNum <= perLineTokens.count {
            tokens = perLineTokens[lineNum - 1]
        } else {
            tokens = []
        }

        let attrString = attributedStringCache.get(
            row: row,
            rowData: rowData,
            lineTokens: tokens,
            appearance: appearance
        )

        cell.configure(row: rowData, attributedText: attrString, appearance: appearance)

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard row < rowHeights.count else { return defaultRowHeight }
        return rowHeights[row]
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }
}
