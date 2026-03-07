import Foundation

enum DiffLineType: Sendable {
    case unchanged
    case added
    case removed
    case modified
}

enum DiffWordType: Sendable {
    case unchanged
    case added
    case removed
}

struct DiffWord: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let type: DiffWordType
}

struct DiffLine: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let type: DiffLineType
    let lineNumberLeft: Int?
    let lineNumberRight: Int?
    let words: [DiffWord]

    init(text: String, type: DiffLineType, lineNumberLeft: Int? = nil, lineNumberRight: Int? = nil, words: [DiffWord] = []) {
        self.text = text
        self.type = type
        self.lineNumberLeft = lineNumberLeft
        self.lineNumberRight = lineNumberRight
        self.words = words
    }
}

struct DiffHunk: Identifiable, Sendable {
    let id = UUID()
    let startLineLeft: Int
    let startLineRight: Int
    let lines: [DiffLine]

    var header: String {
        let leftCount = lines.filter { $0.lineNumberLeft != nil }.count
        let rightCount = lines.filter { $0.lineNumberRight != nil }.count
        return "@@ -\(startLineLeft),\(leftCount) +\(startLineRight),\(rightCount) @@"
    }
}

struct DiffStats: Sendable {
    let added: Int
    let removed: Int
    let modified: Int
}

struct DiffResult: Sendable {
    let hunks: [DiffHunk]
    let stats: DiffStats
    let leftLines: [DiffLine]
    let rightLines: [DiffLine]

    static let empty = DiffResult(hunks: [], stats: DiffStats(added: 0, removed: 0, modified: 0), leftLines: [], rightLines: [])
}
