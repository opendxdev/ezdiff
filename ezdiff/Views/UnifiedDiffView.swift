import SwiftUI

struct UnifiedDiffView: View {
    @ObservedObject var leftFile: DiffFile
    @ObservedObject var rightFile: DiffFile
    let leftTokens: [HighlightToken]
    let rightTokens: [HighlightToken]
    let diffResult: DiffResult
    @StateObject private var rowHeightCoordinator = RowHeightCoordinator()
    let wordWrapEnabled: Bool
    let fontSize: CGFloat
    let onLeftFileDrop: (URL) -> Void
    let onRightFileDrop: (URL) -> Void
    let onRecentPairSelected: (RecentPair) -> Void

    @State private var paneWidth: CGFloat = 800

    var body: some View {
        let leftPerLineTokens = TokenLineSplitter.split(tokens: leftTokens, source: leftFile.content)
        let rightPerLineTokens = TokenLineSplitter.split(tokens: rightTokens, source: rightFile.content)

        let rows: [any DiffRowData] = diffResult.unifiedLines.map {
            UnifiedRowData(diffLine: $0)
        }

        let rowHeights = rowHeightCoordinator.rowHeights
        let gen = rowHeightCoordinator.generation

        GeometryReader { geo in
            VStack(spacing: 0) {
                if leftFile.isEmpty && rightFile.isEmpty {
                    DropZoneView(
                        onFileDrop: onLeftFileDrop,
                        onRecentPairSelected: onRecentPairSelected
                    )
                } else if leftFile.isEmpty || rightFile.isEmpty {
                    DropZoneView(
                        onFileDrop: leftFile.isEmpty ? onLeftFileDrop : onRightFileDrop,
                        onRecentPairSelected: onRecentPairSelected
                    )
                } else {
                    unifiedHeader
                    Divider()
                    UnifiedTableRepresentable(
                        rows: rows,
                        rowHeights: rowHeights,
                        perLineTokens: buildPerLineTokens(
                            leftPerLineTokens: leftPerLineTokens,
                            rightPerLineTokens: rightPerLineTokens
                        ),
                        wordWrapEnabled: wordWrapEnabled,
                        generation: gen
                    )
                }
            }
            .onChange(of: diffResult) { _, _ in
                triggerRecompute()
            }
            .onChange(of: geo.size.width) { _, newWidth in
                paneWidth = newWidth
            }
            .onAppear {
                paneWidth = geo.size.width
            }
        }
        .task(id: UnifiedDataKey(
            lineCount: diffResult.unifiedLines.count,
            leftTokenCount: leftTokens.count,
            rightTokenCount: rightTokens.count,
            wordWrap: wordWrapEnabled,
            paneWidth: Int(paneWidth),
            fontSize: Int(fontSize)
        )) {
            triggerRecompute()
        }
    }

    private var unifiedHeader: some View {
        HStack(spacing: Constants.Header.hStackSpacing) {
            // Left file info
            Text(leftFile.detectedLanguage.displayName)
                .font(.caption2)
                .padding(.horizontal, Constants.Header.badgeHPadding)
                .padding(.vertical, Constants.Header.badgeVPadding)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Header.badgeCornerRadius))

            Text(leftFile.filename)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            Text("↔")
                .foregroundStyle(.secondary)

            Text(rightFile.filename)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.horizontal, Constants.Header.horizontalPadding)
        .padding(.vertical, Constants.Header.verticalPadding)
        .background(.bar)
    }

    /// Build a combined per-line token array for unified view.
    /// For each unified line, pick tokens from left or right source based on diff type.
    private func buildPerLineTokens(
        leftPerLineTokens: [[LineHighlightToken]],
        rightPerLineTokens: [[LineHighlightToken]]
    ) -> [[LineHighlightToken]] {
        diffResult.unifiedLines.map { line in
            switch line.type {
            case .added:
                if let num = line.lineNumberRight, num > 0, num <= rightPerLineTokens.count {
                    return rightPerLineTokens[num - 1]
                }
                return []
            default:
                if let num = line.lineNumberLeft, num > 0, num <= leftPerLineTokens.count {
                    return leftPerLineTokens[num - 1]
                }
                return []
            }
        }
    }

    private func triggerRecompute() {
        rowHeightCoordinator.recomputeUnified(
            lines: diffResult.unifiedLines,
            containerWidth: paneWidth,
            wordWrapEnabled: wordWrapEnabled
        )
    }
}

private struct UnifiedDataKey: Equatable {
    let lineCount: Int
    let leftTokenCount: Int
    let rightTokenCount: Int
    let wordWrap: Bool
    let paneWidth: Int
    let fontSize: Int
}
