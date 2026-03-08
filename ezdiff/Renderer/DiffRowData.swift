import Foundation

struct LineHighlightToken {
    let range: Range<String.Index>
    let type: TokenType
}

protocol DiffRowData {
    var text: String { get }
    var lineNumber: Int? { get }
    var leftLineNumber: Int? { get }
    var rightLineNumber: Int? { get }
    var diffType: DiffLineType { get }
    var isPlaceholder: Bool { get }
    var words: [DiffWord] { get }
    var side: PaneSide { get }
}

extension DiffRowData {
    var leftLineNumber: Int? { nil }
    var rightLineNumber: Int? { nil }
}

struct SideBySideRowData: DiffRowData {
    let diffLine: DiffLine
    let side: PaneSide

    var text: String { diffLine.text }

    var lineNumber: Int? {
        side == .left ? diffLine.lineNumberLeft : diffLine.lineNumberRight
    }

    var diffType: DiffLineType { diffLine.type }

    var isPlaceholder: Bool { lineNumber == nil }

    var words: [DiffWord] { diffLine.words }
}

struct UnifiedRowData: DiffRowData {
    let diffLine: DiffLine
    let side: PaneSide = .left

    var text: String { diffLine.text }
    var lineNumber: Int? { diffLine.lineNumberLeft ?? diffLine.lineNumberRight }
    var leftLineNumber: Int? { diffLine.lineNumberLeft }
    var rightLineNumber: Int? { diffLine.lineNumberRight }
    var diffType: DiffLineType { diffLine.type }
    var isPlaceholder: Bool { false }
    var words: [DiffWord] { diffLine.words }
}
