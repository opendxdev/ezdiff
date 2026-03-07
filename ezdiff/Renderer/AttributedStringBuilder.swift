import AppKit

enum AttributedStringBuilder {

    /// Builds a styled NSAttributedString for a single diff row.
    /// Layers: base font → syntax colors → diff line background → word-level highlights.
    static func build(
        row: any DiffRowData,
        lineTokens: [LineHighlightToken],
        appearance: AppearanceManager
    ) -> NSAttributedString {
        let text = row.text
        guard !text.isEmpty else {
            return NSAttributedString(string: "", attributes: [
                .font: appearance.codeFont,
                .foregroundColor: appearance.defaultTextColor
            ])
        }

        let result = NSMutableAttributedString(string: text, attributes: [
            .font: appearance.codeFont,
            .foregroundColor: appearance.defaultTextColor
        ])

        // Layer 1: Syntax token colors
        let theme = appearance.syntaxTheme
        for token in lineTokens {
            let nsRange = NSRange(token.range, in: text)
            let color = theme.color(for: token.type)
            result.addAttribute(.foregroundColor, value: color, range: nsRange)

            if token.type == .keyword {
                result.addAttribute(.font, value: appearance.codeBoldFont, range: nsRange)
            }

            if let bgColor = theme.backgroundColor(for: token.type) {
                result.addAttribute(.backgroundColor, value: bgColor, range: nsRange)
            }
        }

        // Layer 2: Diff line background (full line)
        if row.diffType != .unchanged {
            let bgColor = appearance.diffLineBackground(for: row.diffType)
            if bgColor != .clear {
                let fullRange = NSRange(location: 0, length: result.length)
                result.addAttribute(.backgroundColor, value: bgColor, range: fullRange)
            }
        }

        // Layer 3: Word-level highlights for modified lines
        if row.diffType == .modified && !row.words.isEmpty {
            applyWordHighlights(to: result, words: row.words, appearance: appearance)
        }

        return result
    }

    private static func applyWordHighlights(
        to attrString: NSMutableAttributedString,
        words: [DiffWord],
        appearance: AppearanceManager
    ) {
        var offset = 0
        let length = attrString.length

        for word in words {
            let wordLen = (word.text as NSString).length
            guard offset + wordLen <= length else { break }

            if word.type != .unchanged {
                let range = NSRange(location: offset, length: wordLen)
                let bgColor = appearance.diffWordBackground(for: word.type)
                if bgColor != .clear {
                    attrString.addAttribute(.backgroundColor, value: bgColor, range: range)
                }
            }
            offset += wordLen
        }
    }
}
