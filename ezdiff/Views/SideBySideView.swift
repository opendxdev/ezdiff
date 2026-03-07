import SwiftUI

struct SideBySideView: View {
    @ObservedObject var leftFile: DiffFile
    @ObservedObject var rightFile: DiffFile
    let leftTokens: [HighlightToken]
    let rightTokens: [HighlightToken]
    let diffResult: DiffResult
    @ObservedObject var scrollCoordinator: SyncScrollCoordinator
    let wordWrapEnabled: Bool
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
                tokens: leftTokens,
                diffLines: diffResult.leftLines,
                side: .left,
                wordWrapEnabled: wordWrapEnabled,
                onFileDrop: onLeftFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearLeft,
                onFocus: { onFocusChanged?(.left) },
                onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .left) }
            )

            Divider()

            DiffPaneView(
                file: rightFile,
                tokens: rightTokens,
                diffLines: diffResult.rightLines,
                side: .right,
                wordWrapEnabled: wordWrapEnabled,
                onFileDrop: onRightFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearRight,
                onFocus: { onFocusChanged?(.right) },
                onScrollViewReady: { scrollCoordinator.register(scrollView: $0, side: .right) }
            )
        }
    }
}
