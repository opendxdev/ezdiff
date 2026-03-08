import SwiftUI

struct SideBySideView: View {
    @ObservedObject var leftFile: DiffFile
    @ObservedObject var rightFile: DiffFile
    let leftTokens: [HighlightToken]
    let rightTokens: [HighlightToken]
    let diffResult: DiffResult
    @ObservedObject var scrollCoordinator: SyncScrollCoordinator
    @ObservedObject var rowHeightCoordinator: RowHeightCoordinator
    let wordWrapEnabled: Bool
    let onLeftFileDrop: (URL) -> Void
    let onRightFileDrop: (URL) -> Void
    let onRecentPairSelected: (RecentPair) -> Void
    let onClearLeft: () -> Void
    let onClearRight: () -> Void

    @State private var paneWidth: CGFloat = 600

    var body: some View {
        let leftPerLineTokens = TokenLineSplitter.split(tokens: leftTokens, source: leftFile.content)
        let rightPerLineTokens = TokenLineSplitter.split(tokens: rightTokens, source: rightFile.content)

        let leftRows: [any DiffRowData] = diffResult.leftLines.map {
            SideBySideRowData(diffLine: $0, side: .left)
        }
        let rightRows: [any DiffRowData] = diffResult.rightLines.map {
            SideBySideRowData(diffLine: $0, side: .right)
        }

        let rowHeights = rowHeightCoordinator.rowHeights
        let gen = rowHeightCoordinator.generation

        GeometryReader { geo in
            HStack(spacing: 0) {
                DiffPaneView(
                    file: leftFile,
                    rows: leftRows,
                    rowHeights: rowHeights,
                    perLineTokens: leftPerLineTokens,
                    side: .left,
                    wordWrapEnabled: wordWrapEnabled,
                    generation: gen,
                    onFileDrop: onLeftFileDrop,
                    onRecentPairSelected: onRecentPairSelected,
                    onClear: onClearLeft,
                    onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .left) }
                )

                Divider()

                DiffPaneView(
                    file: rightFile,
                    rows: rightRows,
                    rowHeights: rowHeights,
                    perLineTokens: rightPerLineTokens,
                    side: .right,
                    wordWrapEnabled: wordWrapEnabled,
                    generation: gen,
                    onFileDrop: onRightFileDrop,
                    onRecentPairSelected: onRecentPairSelected,
                    onClear: onClearRight,
                    onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .right) }
                )
            }
            .onChange(of: geo.size.width) { _, newWidth in
                paneWidth = newWidth / 2
            }
            .onAppear {
                paneWidth = geo.size.width / 2
            }
        }
        .task(id: DiffDataKey(
            leftCount: diffResult.leftLines.count,
            rightCount: diffResult.rightLines.count,
            leftTokenCount: leftTokens.count,
            rightTokenCount: rightTokens.count,
            wordWrap: wordWrapEnabled,
            paneWidth: Int(paneWidth)
        )) {
            triggerRecompute()
        }
    }

    private func triggerRecompute() {
        rowHeightCoordinator.recompute(
            leftLines: diffResult.leftLines,
            rightLines: diffResult.rightLines,
            containerWidth: paneWidth,
            wordWrapEnabled: wordWrapEnabled
        )
    }
}

private struct DiffDataKey: Equatable {
    let leftCount: Int
    let rightCount: Int
    let leftTokenCount: Int
    let rightTokenCount: Int
    let wordWrap: Bool
    let paneWidth: Int
}
