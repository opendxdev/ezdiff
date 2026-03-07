import SwiftUI
import AppKit

struct DiffPaneView: View {
    @ObservedObject var file: DiffFile
    let tokens: [HighlightToken]
    let diffLines: [DiffLine]
    let side: PaneSide
    let wordWrapEnabled: Bool
    let onFileDrop: (URL) -> Void
    let onRecentPairSelected: ((RecentPair) -> Void)?
    let onClear: () -> Void
    let onFocus: (() -> Void)?
    let onScrollViewReady: ((NSScrollView) -> Void)?

    @State private var lineLayouts: [LineLayout] = []
    @State private var gutterView: GutterNSView?

    var body: some View {
        VStack(spacing: 0) {
            if file.isEmpty {
                DropZoneView(
                    onFileDrop: onFileDrop,
                    onRecentPairSelected: onRecentPairSelected
                )
            } else {
                headerBar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        GutterRepresentable(
                            hasContent: !file.isEmpty,
                            lineLayouts: lineLayouts,
                            onGutterReady: { gutterView = $0 }
                        )
                        .frame(width: GutterNSView.gutterWidth)
                        EditorTextView(
                            file: file,
                            tokens: tokens,
                            diffLines: diffLines,
                            side: side,
                            wordWrapEnabled: wordWrapEnabled,
                            onFocus: onFocus,
                            gutterView: gutterView,
                            onLineLayoutChange: { lineLayouts = $0 },
                            onScrollViewReady: onScrollViewReady
                        )
                    }
                }
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
