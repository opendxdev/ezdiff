import SwiftUI

struct SideBySideView: View {
    @ObservedObject var leftFile: DiffFile
    @ObservedObject var rightFile: DiffFile
    let diffResult: DiffResult
    let leftTokens: [HighlightToken]
    let rightTokens: [HighlightToken]
    let syncCoordinator: SyncScrollCoordinator
    let onLeftFileDrop: (URL) -> Void
    let onRightFileDrop: (URL) -> Void
    let onRecentPairSelected: (RecentPair) -> Void
    let onClearLeft: () -> Void
    let onClearRight: () -> Void
    let onFocusChanged: ((PaneSide) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            DiffPaneView(
                file: leftFile,
                diffLines: diffResult.leftLines,
                tokens: leftTokens,
                side: .left,
                syncCoordinator: syncCoordinator,
                onFileDrop: onLeftFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearLeft,
                onFocus: { onFocusChanged?(.left) }
            )

            Divider()

            DiffPaneView(
                file: rightFile,
                diffLines: diffResult.rightLines,
                tokens: rightTokens,
                side: .right,
                syncCoordinator: syncCoordinator,
                onFileDrop: onRightFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearRight,
                onFocus: { onFocusChanged?(.right) }
            )
        }
    }
}
