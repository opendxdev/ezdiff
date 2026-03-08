import SwiftUI

enum DisplayMode: String {
    case sideBySide
    case unified
}

struct ToolbarView: ToolbarContent {
    @Binding var displayMode: DisplayMode
    @Binding var ignoreWhitespace: Bool
    @Binding var wordWrapEnabled: Bool
    let onCopyDiff: () -> Void
    let onExportDiff: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let canUndo: Bool
    let canRedo: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                onUndo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canUndo)
            .help("Undo (⌘Z)")

            Button {
                onRedo()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!canRedo)
            .help("Redo (⇧⌘Z)")

            Divider()

            Button {
                displayMode = displayMode == .sideBySide ? .unified : .sideBySide
            } label: {
                Label(
                    displayMode == .sideBySide ? "Unified" : "Side by Side",
                    systemImage: displayMode == .sideBySide ? "list.bullet.rectangle" : "rectangle.split.2x1"
                )
            }
            .help("Toggle side-by-side / unified view (⌘D)")

            Divider()

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
