import Foundation

struct LineHighlightToken {
    let range: Range<String.Index>
    let type: TokenType
}

protocol DiffRowData {
    var text: String { get }
    var lineNumber: Int? { get }
    var diffType: DiffLineType { get }
    var isPlaceholder: Bool { get }
    var words: [DiffWord] { get }
    var side: PaneSide { get }
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
