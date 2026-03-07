import Testing
@testable import ezdiff

struct DiffEngineTests {

    @Test func identicalFilesProduceNoChanges() {
        let text = "line 1\nline 2\nline 3"
        let result = DiffEngine.computeDiff(left: text, right: text)
        #expect(result.stats.added == 0)
        #expect(result.stats.removed == 0)
        #expect(result.stats.modified == 0)
        #expect(result.hunks.isEmpty)
    }

    @Test func completelyDifferentFiles() {
        let left = "aaa\nbbb\nccc"
        let right = "xxx\nyyy\nzzz"
        let result = DiffEngine.computeDiff(left: left, right: right)
        #expect(result.stats.modified == 3)
    }

    @Test func singleLineAdded() {
        let left = "line 1\nline 3"
        let right = "line 1\nline 2\nline 3"
        let result = DiffEngine.computeDiff(left: left, right: right)
        #expect(result.stats.added == 1)
    }

    @Test func singleLineRemoved() {
        let left = "line 1\nline 2\nline 3"
        let right = "line 1\nline 3"
        let result = DiffEngine.computeDiff(left: left, right: right)
        #expect(result.stats.removed == 1)
    }

    @Test func singleLineModified() {
        let left = "hello world"
        let right = "hello planet"
        let result = DiffEngine.computeDiff(left: left, right: right)
        #expect(result.stats.modified == 1)
    }

    @Test func wordLevelDiff() {
        let words = DiffEngine.diffWords("hello world", "hello planet")
        let changedWords = words.filter { $0.type != .unchanged }
        #expect(changedWords.count >= 1)
    }

    @Test func ignoreWhitespace() {
        let left = "  hello  "
        let right = "hello"
        let result = DiffEngine.computeDiff(left: left, right: right, ignoreWhitespace: true)
        #expect(result.stats.added == 0)
        #expect(result.stats.removed == 0)
        #expect(result.stats.modified == 0)
    }

    @Test func emptyLeftFile() {
        let result = DiffEngine.computeDiff(left: "", right: "line 1\nline 2")
        #expect(result.stats.added >= 1)
    }

    @Test func emptyRightFile() {
        let result = DiffEngine.computeDiff(left: "line 1\nline 2", right: "")
        #expect(result.stats.removed >= 1)
    }

    @Test func bothFilesEmpty() {
        let result = DiffEngine.computeDiff(left: "", right: "")
        #expect(result.stats.added == 0)
        #expect(result.stats.removed == 0)
        #expect(result.stats.modified == 0)
    }

    @Test func hunkGrouping() {
        var leftLines = [String]()
        var rightLines = [String]()
        for i in 0..<20 {
            leftLines.append("line \(i)")
            if i == 5 {
                rightLines.append("changed line 5")
            } else if i == 15 {
                rightLines.append("changed line 15")
            } else {
                rightLines.append("line \(i)")
            }
        }
        let result = DiffEngine.computeDiff(left: leftLines.joined(separator: "\n"), right: rightLines.joined(separator: "\n"))
        // Two changes far apart should produce 2 hunks
        #expect(result.hunks.count == 2)
    }

    @Test func largeFilePerformance() {
        let lines = (0..<1000).map { "line number \($0) with some content" }
        var modifiedLines = lines
        modifiedLines[100] = "modified line 100"
        modifiedLines[500] = "modified line 500"
        modifiedLines[999] = "modified line 999"

        let left = lines.joined(separator: "\n")
        let right = modifiedLines.joined(separator: "\n")

        let start = Date()
        let result = DiffEngine.computeDiff(left: left, right: right)
        let elapsed = Date().timeIntervalSince(start)

        #expect(result.stats.modified == 3)
        #expect(elapsed < 1.0)
    }
}
