import Foundation

enum TokenLineSplitter {

    /// Splits full-source HighlightTokens into per-line LineHighlightTokens.
    /// Both tokens and lines are walked in order — O(tokens + lines).
    static func split(tokens: [HighlightToken], source: String) -> [[LineHighlightToken]] {
        guard !source.isEmpty else { return [] }

        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var result = [[LineHighlightToken]](repeating: [], count: lines.count)

        guard !tokens.isEmpty else { return result }

        // Build line ranges (start index, end index) in the source
        var lineRanges: [(start: String.Index, end: String.Index)] = []
        lineRanges.reserveCapacity(lines.count)

        var pos = source.startIndex
        for line in lines {
            let lineStart = pos
            let lineEnd = source.index(lineStart, offsetBy: line.count)
            lineRanges.append((lineStart, lineEnd))
            // Skip past the newline character (if not at end)
            if lineEnd < source.endIndex {
                pos = source.index(after: lineEnd)
            } else {
                pos = lineEnd
            }
        }

        // Walk tokens, mapping each to overlapping lines
        var tokenIdx = 0
        for lineIdx in 0..<lineRanges.count {
            let (lineStart, lineEnd) = lineRanges[lineIdx]

            // Skip tokens that end before this line
            while tokenIdx < tokens.count && tokens[tokenIdx].range.upperBound <= lineStart {
                tokenIdx += 1
            }

            // Collect tokens that overlap this line
            var ti = tokenIdx
            while ti < tokens.count && tokens[ti].range.lowerBound < lineEnd {
                let token = tokens[ti]

                // Clip token range to line bounds
                let clippedStart = max(token.range.lowerBound, lineStart)
                let clippedEnd = min(token.range.upperBound, lineEnd)

                if clippedStart < clippedEnd {
                    // Convert to line-relative range
                    let relativeStart = source.distance(from: lineStart, to: clippedStart)
                    let relativeEnd = source.distance(from: lineStart, to: clippedEnd)
                    let lineText = String(lines[lineIdx])
                    let startIdx = lineText.index(lineText.startIndex, offsetBy: relativeStart)
                    let endIdx = lineText.index(lineText.startIndex, offsetBy: relativeEnd)

                    result[lineIdx].append(LineHighlightToken(
                        range: startIdx..<endIdx,
                        type: token.type
                    ))
                }

                ti += 1
            }
        }

        return result
    }
}
