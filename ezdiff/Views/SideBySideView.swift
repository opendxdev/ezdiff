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
    let onLineEdit: ((PaneSide, Int, String) -> Void)?

    @State private var dividerRatio: CGFloat = 0.5
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
            let totalWidth = geo.size.width
            let dividerWidth = Constants.PaneDivider.width
            let availableWidth = totalWidth - dividerWidth
            let leftWidth = availableWidth * dividerRatio
            let rightWidth = availableWidth * (1 - dividerRatio)

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
                    onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .left) },
                    onLineEdit: { lineNum, newText in
                        onLineEdit?(.left, lineNum, newText)
                    }
                )
                .frame(width: leftWidth)

                DraggableDivider()
                    .gesture(
                        DragGesture(coordinateSpace: .named("sideBySide"))
                            .onChanged { value in
                                let newRatio = value.location.x / availableWidth
                                dividerRatio = min(max(newRatio, Constants.PaneDivider.minPaneRatio), 1 - Constants.PaneDivider.minPaneRatio)
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dividerRatio = 0.5
                        }
                    }

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
                    onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .right) },
                    onLineEdit: { lineNum, newText in
                        onLineEdit?(.right, lineNum, newText)
                    }
                )
                .frame(width: rightWidth)
            }
            .onChange(of: geo.size.width) { _, _ in
                updatePaneWidth(totalWidth: totalWidth, dividerWidth: dividerWidth)
            }
            .onChange(of: dividerRatio) { _, _ in
                updatePaneWidth(totalWidth: totalWidth, dividerWidth: dividerWidth)
            }
            .onAppear {
                updatePaneWidth(totalWidth: totalWidth, dividerWidth: dividerWidth)
            }
        }
        .coordinateSpace(name: "sideBySide")
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

    private func updatePaneWidth(totalWidth: CGFloat, dividerWidth: CGFloat) {
        let availableWidth = totalWidth - dividerWidth
        // Use the narrower pane for height calculation (ensures text fits in both)
        paneWidth = availableWidth * min(dividerRatio, 1 - dividerRatio)
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
