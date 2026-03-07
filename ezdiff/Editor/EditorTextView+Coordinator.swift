import AppKit
import QuartzCore

extension EditorTextView {

    struct HighlightState: Equatable {
        var tokenCount: Int = -1
        var diffLineCount: Int = -1
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        weak var file: DiffFile?
        var onFocus: (() -> Void)?
        var onScrollChange: ((CGFloat) -> Void)?
        var onLineLayoutChange: (([LineLayout]) -> Void)?
        var isUpdatingFromExternal = false
        var scrollObserver: NSObjectProtocol?
        var lastHighlightState = HighlightState()

        // Layout cache keys — only recompute when these change
        var lastLayoutText: String = ""
        var lastLayoutContainerWidth: CGFloat = 0

        // Scroll throttle — cap SwiftUI state updates at display refresh rate
        private var lastScrollTime: CFTimeInterval = 0

        func throttledScrollUpdate(_ offset: CGFloat) {
            let now = CACurrentMediaTime()
            guard now - lastScrollTime >= 1.0 / 60.0 else { return }
            lastScrollTime = now
            onScrollChange?(offset)
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromExternal,
                  let textView = notification.object as? NSTextView,
                  let file = file
            else { return }

            let newContent = textView.string
            if newContent != file.content {
                file.content = newContent
                file.markEdited()
            }
        }

        func textDidBeginEditing(_ notification: Notification) {
            onFocus?()
        }

        deinit {
            if let obs = scrollObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }
}
