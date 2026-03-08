import Foundation

enum DiffLineType: Sendable, Equatable {
    case unchanged
    case added
    case removed
    case modified
}

enum DiffWordType: Sendable, Equatable {
    case unchanged
    case added
    case removed
}

struct DiffWord: Sendable, Equatable {
    let text: String
    let type: DiffWordType
}

struct DiffLine: Sendable, Equatable {
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

struct DiffHunk: Sendable, Equatable {
    let startLineLeft: Int
    let startLineRight: Int
    let lines: [DiffLine]

    var header: String {
        let leftCount = lines.filter { $0.lineNumberLeft != nil }.count
        let rightCount = lines.filter { $0.lineNumberRight != nil }.count
        return "@@ -\(startLineLeft),\(leftCount) +\(startLineRight),\(rightCount) @@"
    }
}

struct DiffStats: Sendable, Equatable {
    let added: Int
    let removed: Int
    let modified: Int
}

struct DiffResult: Sendable, Equatable {
    let hunks: [DiffHunk]
    let stats: DiffStats
    let leftLines: [DiffLine]
    let rightLines: [DiffLine]

    static let empty = DiffResult(hunks: [], stats: DiffStats(added: 0, removed: 0, modified: 0), leftLines: [], rightLines: [])

    /// Maps each hunk to its first row index in the leftLines/rightLines arrays.
    var hunkStartRows: [Int] {
        guard !hunks.isEmpty, !leftLines.isEmpty else { return [] }
        var result = [Int]()
        for hunk in hunks {
            guard let firstChangedLine = hunk.lines.first(where: { $0.type != .unchanged }) else { continue }
            let targetLineLeft = firstChangedLine.lineNumberLeft
            let targetLineRight = firstChangedLine.lineNumberRight
            for (i, line) in leftLines.enumerated() {
                if let tl = targetLineLeft, line.lineNumberLeft == tl {
                    result.append(i)
                    break
                }
                if let tr = targetLineRight, line.lineNumberRight == tr {
                    result.append(i)
                    break
                }
            }
        }
        return result
    }
}
