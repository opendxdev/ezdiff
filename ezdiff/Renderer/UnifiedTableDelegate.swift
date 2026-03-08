import AppKit

final class UnifiedTableDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    var rows: [any DiffRowData] = []
    var rowHeights: [CGFloat] = []
    var perLineTokens: [[LineHighlightToken]] = []
    var appearance: AppearanceManager = .shared
    var attributedStringCache = AttributedStringCache()

    private let defaultRowHeight: CGFloat

    override init() {
        defaultRowHeight = AppearanceManager.shared.singleLineHeight + Constants.UnifiedCell.verticalPadding
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
            withIdentifier: UnifiedRowCellView.identifier,
            owner: nil
        ) as? UnifiedRowCellView ?? UnifiedRowCellView(frame: .zero)
        cell.identifier = UnifiedRowCellView.identifier

        let rowData = rows[row]

        // perLineTokens is indexed by row (built by UnifiedDiffView)
        let tokens: [LineHighlightToken] = row < perLineTokens.count ? perLineTokens[row] : []

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
