import SwiftUI
import AppKit

struct DiffPaneView: View {
    @ObservedObject var file: DiffFile
    let rows: [any DiffRowData]
    let rowHeights: [CGFloat]
    let perLineTokens: [[LineHighlightToken]]
    let side: PaneSide
    let wordWrapEnabled: Bool
    let generation: Int
    let onFileDrop: (URL) -> Void
    let onRecentPairSelected: ((RecentPair) -> Void)?
    let onClear: () -> Void
    let onScrollViewReady: ((NSScrollView) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if file.isEmpty {
                DropZoneView(
                    onFileDrop: onFileDrop,
                    onRecentPairSelected: onRecentPairSelected
                )
                .accessibilityIdentifier(side == .left ? "leftDropZone" : "rightDropZone")
            } else {
                headerBar
                DiffTableRepresentable(
                    rows: rows,
                    rowHeights: rowHeights,
                    perLineTokens: perLineTokens,
                    side: side,
                    wordWrapEnabled: wordWrapEnabled,
                    generation: generation,
                    onScrollViewReady: onScrollViewReady,
                    onRowAction: nil
                )
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Text(file.detectedLanguage.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(file.filename)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            if file.hasUnsavedChanges {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
            }

            Spacer()

            if let date = file.lastModified {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onClear()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
