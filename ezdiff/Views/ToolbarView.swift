import SwiftUI

enum DisplayMode: String {
    case sideBySide
    case unified
}

struct ToolbarView: ToolbarContent {
    @Binding var displayMode: DisplayMode
    @Binding var showPreview: Bool
    @Binding var vimModeEnabled: Bool
    @Binding var ignoreWhitespace: Bool
    let canShowPreview: Bool
    let onCopyDiff: () -> Void
    let onExportDiff: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                displayMode = displayMode == .sideBySide ? .unified : .sideBySide
            } label: {
                Image(systemName: displayMode == .sideBySide ? "rectangle.split.2x1" : "rectangle")
            }
            .help("Toggle display mode (\u{2318}D)")

            Button {
                showPreview.toggle()
            } label: {
                Image(systemName: showPreview ? "eye.fill" : "eye")
            }
            .help("Toggle preview (\u{2318}P)")
            .disabled(!canShowPreview)

            Button {
                vimModeEnabled.toggle()
            } label: {
                Image(systemName: vimModeEnabled ? "terminal.fill" : "terminal")
            }
            .help("Toggle Vim mode (\u{2318}\u{2325}V)")

            Button {
                ignoreWhitespace.toggle()
            } label: {
                Image(systemName: ignoreWhitespace ? "textformat.abc.dottedunderline" : "textformat.abc")
            }
            .help("Ignore whitespace (\u{2318}\u{2325}W)")

            Divider()

            Button {
                onCopyDiff()
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .help("Copy diff (\u{2318}\u{21E7}C)")

            Button {
                onExportDiff()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Export diff (\u{2318}\u{21E7}E)")
        }
    }
}
