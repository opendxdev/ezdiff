import SwiftUI

enum DisplayMode: String {
    case sideBySide
    case unified
}

struct ToolbarView: ToolbarContent {
    @Binding var ignoreWhitespace: Bool
    @Binding var wordWrapEnabled: Bool
    let onCopyDiff: () -> Void
    let onExportDiff: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Toggle(isOn: $wordWrapEnabled) {
                Label("Wrap", systemImage: wordWrapEnabled ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
            }
            .help("Toggle word wrap")

            Toggle(isOn: $ignoreWhitespace) {
                Label("Whitespace", systemImage: ignoreWhitespace ? "eye.slash" : "eye")
            }
            .help("Ignore whitespace changes")

            Divider()

            Button {
                onCopyDiff()
            } label: {
                Label("Copy Diff", systemImage: "doc.on.clipboard")
            }
            .help("Copy diff to clipboard")

            Button {
                onExportDiff()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .help("Export diff as patch file")
        }
    }
}
