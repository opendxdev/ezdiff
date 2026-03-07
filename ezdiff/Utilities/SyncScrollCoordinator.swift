import AppKit
import Combine

enum PaneSide {
    case left, right
}

@MainActor
class SyncScrollCoordinator: ObservableObject {
    private var leftScrollView: NSScrollView?
    private var rightScrollView: NSScrollView?
    private var isUpdating = false
    private var leftObserver: NSObjectProtocol?
    private var rightObserver: NSObjectProtocol?

    func register(scrollView: NSScrollView, side: PaneSide) {
        unregister(side: side)

        switch side {
        case .left: leftScrollView = scrollView
        case .right: rightScrollView = scrollView
        }

        scrollView.contentView.postsBoundsChangedNotifications = true

        let observer = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.handleScroll(from: side)
            }
        }

        switch side {
        case .left: leftObserver = observer
        case .right: rightObserver = observer
        }
    }

    func unregister(side: PaneSide) {
        switch side {
        case .left:
            if let obs = leftObserver {
                NotificationCenter.default.removeObserver(obs)
                leftObserver = nil
            }
            leftScrollView = nil
        case .right:
            if let obs = rightObserver {
                NotificationCenter.default.removeObserver(obs)
                rightObserver = nil
            }
            rightScrollView = nil
        }
    }

    func unregisterAll() {
        unregister(side: .left)
        unregister(side: .right)
    }

    private func handleScroll(from side: PaneSide) {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        let (source, target): (NSScrollView?, NSScrollView?) = side == .left
            ? (leftScrollView, rightScrollView)
            : (rightScrollView, leftScrollView)

        guard let sourceView = source, let targetView = target else { return }

        let sourceOrigin = sourceView.contentView.bounds.origin
        targetView.contentView.scroll(to: sourceOrigin)
        targetView.reflectScrolledClipView(targetView.contentView)
    }
}
