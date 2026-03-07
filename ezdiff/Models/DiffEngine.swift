import Foundation

struct DiffEngine: Sendable {

    // MARK: - Public API

    static func computeDiff(left: String, right: String, ignoreWhitespace: Bool = false) -> DiffResult {
        let leftLines = left.components(separatedBy: "\n")
        let rightLines = right.components(separatedBy: "\n")

        let compareLeft = ignoreWhitespace ? leftLines.map { $0.trimmingCharacters(in: .whitespaces) } : leftLines
        let compareRight = ignoreWhitespace ? rightLines.map { $0.trimmingCharacters(in: .whitespaces) } : rightLines

        let editScript = myersDiff(old: compareLeft, new: compareRight)

        // Build line-level diff
        var diffLines = buildDiffLines(editScript: editScript, oldLines: leftLines, newLines: rightLines)

        // Pair up adjacent removed/added lines as modified and do word-level diff
        diffLines = refineModifiedLines(diffLines)

        // Compute stats
        var added = 0, removed = 0, modified = 0
        for line in diffLines {
            switch line.type {
            case .added: added += 1
            case .removed: removed += 1
            case .modified: modified += 1
            case .unchanged: break
            }
        }

        // Group into hunks
        let hunks = buildHunks(from: diffLines, contextLines: 3)

        // Split into left/right line arrays for side-by-side display
        let (leftDiffLines, rightDiffLines) = splitForSideBySide(diffLines)

        return DiffResult(
            hunks: hunks,
            stats: DiffStats(added: added, removed: removed, modified: modified),
            leftLines: leftDiffLines,
            rightLines: rightDiffLines
        )
    }

    // MARK: - Myers Diff Algorithm

    enum EditType {
        case equal
        case insert
        case delete
    }

    struct Edit {
        let type: EditType
        let oldIndex: Int?
        let newIndex: Int?
    }

    static func myersDiff(old: [String], new: [String]) -> [Edit] {
        let n = old.count
        let m = new.count

        if n == 0 && m == 0 { return [] }
        if n == 0 {
            return (0..<m).map { Edit(type: .insert, oldIndex: nil, newIndex: $0) }
        }
        if m == 0 {
            return (0..<n).map { Edit(type: .delete, oldIndex: $0, newIndex: nil) }
        }

        let max = n + m
        var v = [Int: Int]()
        v[1] = 0

        var trace = [[Int: Int]]()

        outer: for d in 0...max {
            trace.append(v)
            var newV = v

            for k in stride(from: -d, through: d, by: 2) {
                var x: Int
                if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                    x = v[k + 1] ?? 0
                } else {
                    x = (v[k - 1] ?? 0) + 1
                }
                var y = x - k

                while x < n && y < m && old[x] == new[y] {
                    x += 1
                    y += 1
                }

                newV[k] = x

                if x >= n && y >= m {
                    trace.append(newV)
                    break outer
                }
            }

            v = newV
        }

        // Backtrack to build the edit script
        return backtrack(trace: trace, old: old, new: new)
    }

    private static func backtrack(trace: [[Int: Int]], old: [String], new: [String]) -> [Edit] {
        var x = old.count
        var y = new.count
        var edits = [Edit]()

        for d in stride(from: trace.count - 2, through: 0, by: -1) {
            let v = trace[d]
            let k = x - y

            var prevK: Int
            if k == -d || (k != d && (v[k - 1] ?? 0) < (v[k + 1] ?? 0)) {
                prevK = k + 1
            } else {
                prevK = k - 1
            }

            let prevX = v[prevK] ?? 0
            let prevY = prevX - prevK

            // Diagonal moves (equals)
            while x > prevX && y > prevY {
                x -= 1
                y -= 1
                edits.append(Edit(type: .equal, oldIndex: x, newIndex: y))
            }

            if d > 0 {
                if x == prevX {
                    // Insert
                    y -= 1
                    edits.append(Edit(type: .insert, oldIndex: nil, newIndex: y))
                } else {
                    // Delete
                    x -= 1
                    edits.append(Edit(type: .delete, oldIndex: x, newIndex: nil))
                }
            }
        }

        return edits.reversed()
    }

    // MARK: - Build diff lines

    private static func buildDiffLines(editScript: [Edit], oldLines: [String], newLines: [String]) -> [DiffLine] {
        var result = [DiffLine]()

        for edit in editScript {
            switch edit.type {
            case .equal:
                let idx = edit.oldIndex!
                let newIdx = edit.newIndex!
                result.append(DiffLine(
                    text: oldLines[idx],
                    type: .unchanged,
                    lineNumberLeft: idx + 1,
                    lineNumberRight: newIdx + 1
                ))
            case .delete:
                let idx = edit.oldIndex!
                result.append(DiffLine(
                    text: oldLines[idx],
                    type: .removed,
                    lineNumberLeft: idx + 1
                ))
            case .insert:
                let idx = edit.newIndex!
                result.append(DiffLine(
                    text: newLines[idx],
                    type: .added,
                    lineNumberRight: idx + 1
                ))
            }
        }

        return result
    }

    // MARK: - Refine modified lines with word-level diff

    private static func refineModifiedLines(_ lines: [DiffLine]) -> [DiffLine] {
        var result = [DiffLine]()
        var i = 0

        while i < lines.count {
            // Look for consecutive removed lines followed by consecutive added lines
            if lines[i].type == .removed {
                var removedLines = [DiffLine]()
                var j = i
                while j < lines.count && lines[j].type == .removed {
                    removedLines.append(lines[j])
                    j += 1
                }

                var addedLines = [DiffLine]()
                while j < lines.count && lines[j].type == .added {
                    addedLines.append(lines[j])
                    j += 1
                }

                if !addedLines.isEmpty {
                    // Pair up removed and added lines as modified
                    let pairCount = min(removedLines.count, addedLines.count)
                    for p in 0..<pairCount {
                        let words = diffWords(removedLines[p].text, addedLines[p].text)
                        result.append(DiffLine(
                            text: removedLines[p].text,
                            type: .modified,
                            lineNumberLeft: removedLines[p].lineNumberLeft,
                            lineNumberRight: addedLines[p].lineNumberRight,
                            words: words
                        ))
                    }
                    // Remaining unpaired lines
                    for p in pairCount..<removedLines.count {
                        result.append(removedLines[p])
                    }
                    for p in pairCount..<addedLines.count {
                        result.append(addedLines[p])
                    }
                } else {
                    result.append(contentsOf: removedLines)
                }

                i = j
            } else {
                result.append(lines[i])
                i += 1
            }
        }

        return result
    }

    // MARK: - Word-level diff

    static func diffWords(_ oldText: String, _ newText: String) -> [DiffWord] {
        let oldWords = tokenizeWords(oldText)
        let newWords = tokenizeWords(newText)

        let edits = myersDiff(old: oldWords, new: newWords)
        var result = [DiffWord]()

        for edit in edits {
            switch edit.type {
            case .equal:
                result.append(DiffWord(text: oldWords[edit.oldIndex!], type: .unchanged))
            case .delete:
                result.append(DiffWord(text: oldWords[edit.oldIndex!], type: .removed))
            case .insert:
                result.append(DiffWord(text: newWords[edit.newIndex!], type: .added))
            }
        }

        return result
    }

    private static func tokenizeWords(_ text: String) -> [String] {
        var words = [String]()
        var current = ""

        for char in text {
            if char.isWhitespace {
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
                words.append(String(char))
            } else if char.isPunctuation || char.isSymbol {
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
                words.append(String(char))
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            words.append(current)
        }

        return words
    }

    // MARK: - Hunk grouping

    private static func buildHunks(from lines: [DiffLine], contextLines: Int) -> [DiffHunk] {
        if lines.isEmpty { return [] }

        // Find indices of changed lines
        var changedIndices = Set<Int>()
        for (i, line) in lines.enumerated() {
            if line.type != .unchanged {
                changedIndices.insert(i)
            }
        }

        if changedIndices.isEmpty { return [] }

        // Expand changed indices by context
        var includedIndices = Set<Int>()
        for idx in changedIndices {
            let start = max(0, idx - contextLines)
            let end = min(lines.count - 1, idx + contextLines)
            for i in start...end {
                includedIndices.insert(i)
            }
        }

        // Group consecutive included indices into hunks
        let sorted = includedIndices.sorted()
        var hunks = [DiffHunk]()
        var currentGroup = [Int]()

        for idx in sorted {
            if let last = currentGroup.last, idx > last + 1 {
                // Gap — start new hunk
                let hunkLines = currentGroup.map { lines[$0] }
                let startLeft = hunkLines.first(where: { $0.lineNumberLeft != nil })?.lineNumberLeft ?? 1
                let startRight = hunkLines.first(where: { $0.lineNumberRight != nil })?.lineNumberRight ?? 1
                hunks.append(DiffHunk(startLineLeft: startLeft, startLineRight: startRight, lines: hunkLines))
                currentGroup = [idx]
            } else {
                currentGroup.append(idx)
            }
        }

        if !currentGroup.isEmpty {
            let hunkLines = currentGroup.map { lines[$0] }
            let startLeft = hunkLines.first(where: { $0.lineNumberLeft != nil })?.lineNumberLeft ?? 1
            let startRight = hunkLines.first(where: { $0.lineNumberRight != nil })?.lineNumberRight ?? 1
            hunks.append(DiffHunk(startLineLeft: startLeft, startLineRight: startRight, lines: hunkLines))
        }

        return hunks
    }

    // MARK: - Side-by-side split

    private static func splitForSideBySide(_ lines: [DiffLine]) -> ([DiffLine], [DiffLine]) {
        var left = [DiffLine]()
        var right = [DiffLine]()

        for line in lines {
            switch line.type {
            case .unchanged:
                left.append(line)
                right.append(line)
            case .removed:
                left.append(line)
                right.append(DiffLine(text: "", type: .unchanged, lineNumberLeft: nil, lineNumberRight: nil))
            case .added:
                left.append(DiffLine(text: "", type: .unchanged, lineNumberLeft: nil, lineNumberRight: nil))
                right.append(line)
            case .modified:
                left.append(DiffLine(
                    text: line.text,
                    type: .modified,
                    lineNumberLeft: line.lineNumberLeft,
                    words: line.words.filter { $0.type != .added }
                ))
                right.append(DiffLine(
                    text: line.words.filter { $0.type != .removed }.map(\.text).joined(),
                    type: .modified,
                    lineNumberRight: line.lineNumberRight,
                    words: line.words.filter { $0.type != .removed }
                ))
            }
        }

        return (left, right)
    }
}
