import SwiftUI

struct SideBySideView: View {
    @ObservedObject var leftFile: DiffFile
    @ObservedObject var rightFile: DiffFile
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
                onFileDrop: onLeftFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearLeft,
                onFocus: { onFocusChanged?(.left) }
            )

            Divider()

            DiffPaneView(
                file: rightFile,
                onFileDrop: onRightFileDrop,
                onRecentPairSelected: onRecentPairSelected,
                onClear: onClearRight,
                onFocus: { onFocusChanged?(.right) }
            )
        }
    }
}
