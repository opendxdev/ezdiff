import AppKit

enum HighlightApplicator {

    /// Applies syntax highlighting and diff background colors in a single editing pass.
    /// Must be called inside a context where textStorage is safe to mutate.
    static func apply(
        to textStorage: NSMutableAttributedString,
        tokens: [HighlightToken],
        diffLines: [DiffLine],
        side: PaneSide,
        source: String,
        font: NSFont
    ) {
        textStorage.beginEditing()

        // Pass 1: Reset to default attributes
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.setAttributes(
            [.font: font, .foregroundColor: NSColor.textColor],
            range: fullRange
        )

        // Pass 2: Syntax highlighting
        if !tokens.isEmpty {
            let theme = SyntaxHighlighter.currentTheme
            SyntaxHighlighter.applyHighlighting(to: textStorage, tokens: tokens, source: source, theme: theme)
        }

        // Pass 3: Diff line + word highlighting
        if !diffLines.isEmpty {
            applyDiffHighlighting(to: textStorage, diffLines: diffLines, side: side, source: source)
        }

        textStorage.endEditing()
    }

    // MARK: - Diff Highlighting

    private static func applyDiffHighlighting(
        to textStorage: NSMutableAttributedString,
        diffLines: [DiffLine],
        side: PaneSide,
        source: String
    ) {
        // Build mapping: file line number (1-based) → DiffLine
        var lineMap: [Int: DiffLine] = [:]
        for diffLine in diffLines {
            let lineNum = side == .left ? diffLine.lineNumberLeft : diffLine.lineNumberRight
            if let num = lineNum {
                lineMap[num] = diffLine
            }
        }

        guard !lineMap.isEmpty else { return }

        // Compute line ranges in source
        let nsSource = source as NSString
        var lineStart = 0
        var lineNumber = 1

        while lineStart <= nsSource.length {
            let lineRange: NSRange
            if lineStart == nsSource.length {
                // Empty last line after trailing newline
                lineRange = NSRange(location: lineStart, length: 0)
            } else {
                lineRange = nsSource.lineRange(for: NSRange(location: lineStart, length: 0))
            }

            if let diffLine = lineMap[lineNumber] {
                // Apply line background
                if diffLine.type != .unchanged && lineRange.length > 0 {
                    DiffHighlighter.applyLineHighlight(to: textStorage, range: lineRange, lineType: diffLine.type)
                }

                // Apply word-level highlights for modified lines
                if diffLine.type == .modified && !diffLine.words.isEmpty {
                    applyWordHighlights(to: textStorage, words: diffLine.words, lineRange: lineRange, source: nsSource)
                }
            }

            lineNumber += 1
            if lineRange.length == 0 { break }
            lineStart = NSMaxRange(lineRange)
            if lineStart == lineRange.location { break } // safety
        }
    }

    private static func applyWordHighlights(
        to textStorage: NSMutableAttributedString,
        words: [DiffWord],
        lineRange: NSRange,
        source: NSString
    ) {
        var offset = lineRange.location
        let lineEnd = NSMaxRange(lineRange)

        for word in words {
            let wordLen = (word.text as NSString).length
            guard offset + wordLen <= lineEnd else { break }

            if word.type != .unchanged {
                let wordRange = NSRange(location: offset, length: wordLen)
                DiffHighlighter.applyWordHighlight(to: textStorage, range: wordRange, wordType: word.type)
            }
            offset += wordLen
        }
    }
}
