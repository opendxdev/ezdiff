import AppKit

extension EditorTextView {

    struct HighlightState: Equatable {
        var tokenCount: Int = -1
        var diffLineCount: Int = -1
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        weak var file: DiffFile?
        var onFocus: (() -> Void)?
        var onScrollChange: ((CGFloat) -> Void)?
        var isUpdatingFromExternal = false
        var scrollObserver: NSObjectProtocol?
        var lastHighlightState = HighlightState()

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
