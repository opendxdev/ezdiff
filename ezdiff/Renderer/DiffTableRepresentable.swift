import SwiftUI
import AppKit

struct DiffTableRepresentable: NSViewRepresentable {
    let rows: [any DiffRowData]
    let rowHeights: [CGFloat]
    let perLineTokens: [[LineHighlightToken]]
    let side: PaneSide
    let wordWrapEnabled: Bool
    let generation: Int
    let onScrollViewReady: ((NSScrollView) -> Void)?
    let onRowAction: ((RowAction) -> Void)?

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
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.gridStyleMask = []
        tableView.selectionHighlightStyle = .none
        tableView.backgroundColor = .clear
        tableView.style = .plain

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let delegate = DiffTableDelegate()
        delegate.rows = rows
        delegate.rowHeights = rowHeights
        delegate.perLineTokens = perLineTokens
        delegate.onRowAction = onRowAction

        tableView.dataSource = delegate
        tableView.delegate = delegate

        context.coordinator.delegate = delegate
        context.coordinator.tableView = tableView
        context.coordinator.lastGeneration = generation

        scrollView.documentView = tableView

        // Size column to fill scroll view width
        tableView.sizeLastColumnToFit()

        onScrollViewReady?(scrollView)

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
        delegate.onRowAction = onRowAction

        if dataChanged {
            delegate.attributedStringCache.invalidateAll()
            tableView.reloadData()
            tableView.sizeLastColumnToFit()
        }
    }

    // MARK: - Coordinator

    class Coordinator {
        var delegate: DiffTableDelegate?
        var tableView: NSTableView?
        var lastGeneration: Int = -1

        func scrollToRow(_ row: Int, animated: Bool) {
            guard let tableView else { return }
            guard row >= 0 && row < tableView.numberOfRows else { return }
            if animated {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.3
                    tableView.scrollRowToVisible(row)
                }
            } else {
                tableView.scrollRowToVisible(row)
            }
        }
    }
}
