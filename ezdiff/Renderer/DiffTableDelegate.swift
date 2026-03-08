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
    var onLineEdit: ((Int, String) -> Void)?

    private let defaultRowHeight: CGFloat
    private weak var editingCell: DiffRowCellView?
    private var editingRow: Int?
    private var editingRowHeight: CGFloat?
    private weak var tableView_: NSTableView?

    override init() {
        defaultRowHeight = AppearanceManager.shared.singleLineHeight + Constants.Cell.verticalPadding
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

        // Wire edit commit callback
        cell.onEditCommit = { [weak self] newText in
            guard let self,
                  let lineNumber = rowData.lineNumber else { return }
            let prevRow = self.editingRow
            self.editingCell = nil
            self.editingRow = nil
            self.editingRowHeight = nil
            if let prevRow, let tv = self.tableView_ {
                tv.noteHeightOfRows(withIndexesChanged: IndexSet(integer: prevRow))
            }
            self.onLineEdit?(lineNumber, newText)
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row == editingRow, let height = editingRowHeight {
            return height
        }
        guard row < rowHeights.count else { return defaultRowHeight }
        return rowHeights[row]
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }

    // MARK: - Edit Activation

    func activateEdit(at row: Int, in tableView: NSTableView) {
        // Exit any existing edit
        editingCell?.exitEditMode()

        guard row < rows.count, rows[row].lineNumber != nil, !rows[row].isPlaceholder else { return }

        guard let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? DiffRowCellView else { return }

        tableView_ = tableView
        editingCell = cell
        editingRow = row

        cell.onTextChanged = { [weak self] in
            self?.updateEditingRowHeight()
        }

        cell.enterEditMode()
        updateEditingRowHeight()
    }

    private func updateEditingRowHeight() {
        guard let cell = editingCell,
              let row = editingRow,
              let tableView = tableView_ else { return }

        let text = cell.currentText
        let font = AppearanceManager.shared.codeFont

        // Calculate available text width: cell width minus gutter, separator, margins, done button
        let cellWidth = cell.frame.width
        let textWidth = cellWidth
            - Constants.Cell.gutterWidth
            - Constants.Cell.separatorWidth
            - Constants.Cell.textLeadingMargin
            - 24  // done button (20) + gap (4)
            - Constants.Cell.textTrailingMargin

        guard textWidth > 0 else { return }

        let boundingRect = (text as NSString).boundingRect(
            with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )

        let calculatedHeight = ceil(boundingRect.height) + Constants.EditMode.verticalPadding + Constants.EditMode.textFieldBorderWidth * 2
        let originalHeight = row < rowHeights.count ? rowHeights[row] : defaultRowHeight
        let newHeight = max(calculatedHeight, originalHeight)

        if editingRowHeight != newHeight {
            editingRowHeight = newHeight
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.1
            tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
            NSAnimationContext.endGrouping()
        }
    }
}
