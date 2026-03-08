import SwiftUI
import AppKit

struct UnifiedTableRepresentable: NSViewRepresentable {
    let rows: [any DiffRowData]
    let rowHeights: [CGFloat]
    let perLineTokens: [[LineHighlightToken]]
    let wordWrapEnabled: Bool
    let generation: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wordWrapEnabled
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.usesAutomaticRowHeights = false
        tableView.intercellSpacing = NSSize(width: 0, height: Constants.UnifiedCell.intercellSpacing)
        tableView.gridStyleMask = []
        tableView.selectionHighlightStyle = .none
        tableView.backgroundColor = .clear
        tableView.style = .plain

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let delegate = UnifiedTableDelegate()
        delegate.rows = rows
        delegate.rowHeights = rowHeights
        delegate.perLineTokens = perLineTokens

        tableView.dataSource = delegate
        tableView.delegate = delegate

        context.coordinator.delegate = delegate
        context.coordinator.tableView = tableView
        context.coordinator.lastGeneration = generation

        scrollView.documentView = tableView
        tableView.sizeLastColumnToFit()

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        guard let delegate = coordinator.delegate,
              let tableView = coordinator.tableView else { return }

        nsView.hasHorizontalScroller = !wordWrapEnabled

        let dataChanged = generation != coordinator.lastGeneration
        coordinator.lastGeneration = generation

        delegate.rows = rows
        delegate.rowHeights = rowHeights
        delegate.perLineTokens = perLineTokens

        if dataChanged {
            delegate.attributedStringCache.invalidateAll()
            tableView.reloadData()
            tableView.sizeLastColumnToFit()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var delegate: UnifiedTableDelegate?
        var tableView: NSTableView?
        var lastGeneration: Int = -1
    }
}
