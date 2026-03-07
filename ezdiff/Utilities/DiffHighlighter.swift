import AppKit
import SwiftUI

struct DiffHighlighter {

    // MARK: - Line-level background colors

    static func lineBackgroundColor(for type: DiffLineType) -> NSColor {
        switch type {
        case .unchanged:
            return .clear
        case .added:
            return NSColor.systemGreen.withAlphaComponent(0.12)
        case .removed:
            return NSColor.systemRed.withAlphaComponent(0.12)
        case .modified:
            return NSColor.systemOrange.withAlphaComponent(0.10)
        }
    }

    static func lineBackgroundSwiftUI(for type: DiffLineType) -> Color {
        switch type {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.12)
        case .removed:
            return Color.red.opacity(0.12)
        case .modified:
            return Color.orange.opacity(0.10)
        }
    }

    // MARK: - Word-level background colors

    static func wordBackgroundColor(for type: DiffWordType) -> NSColor {
        switch type {
        case .unchanged:
            return .clear
        case .added:
            return NSColor.systemGreen.withAlphaComponent(0.25)
        case .removed:
            return NSColor.systemRed.withAlphaComponent(0.25)
        }
    }

    static func wordBackgroundSwiftUI(for type: DiffWordType) -> Color {
        switch type {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.25)
        case .removed:
            return Color.red.opacity(0.25)
        }
    }

    // MARK: - Apply to NSAttributedString

    static func applyLineHighlight(to attrString: NSMutableAttributedString, range: NSRange, lineType: DiffLineType) {
        let bgColor = lineBackgroundColor(for: lineType)
        if bgColor != .clear {
            attrString.addAttribute(.backgroundColor, value: bgColor, range: range)
        }
    }

    static func applyWordHighlight(to attrString: NSMutableAttributedString, range: NSRange, wordType: DiffWordType) {
        let bgColor = wordBackgroundColor(for: wordType)
        if bgColor != .clear {
            attrString.addAttribute(.backgroundColor, value: bgColor, range: range)
        }
    }
}
