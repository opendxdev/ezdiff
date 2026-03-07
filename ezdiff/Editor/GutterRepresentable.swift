import SwiftUI

struct GutterRepresentable: NSViewRepresentable {
    let hasContent: Bool
    let lineLayouts: [LineLayout]
    let onGutterReady: ((GutterNSView) -> Void)?

    func makeNSView(context: Context) -> GutterNSView {
        let view = GutterNSView(frame: .zero)
        onGutterReady?(view)
        return view
    }

    func updateNSView(_ nsView: GutterNSView, context: Context) {
        nsView.hasContent = hasContent
        if nsView.lineLayouts != lineLayouts {
            nsView.lineLayouts = lineLayouts
        }
    }
}
