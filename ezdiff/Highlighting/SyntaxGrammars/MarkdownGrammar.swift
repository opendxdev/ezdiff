import Foundation

struct MarkdownGrammar: SyntaxGrammar {

    static let languageID = "markdown"

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex
        var lineStart = true

        while index < source.endIndex {
            let c = source[index]

            if c == "\n" {
                index = source.index(after: index)
                lineStart = true
                continue
            }

            // --- Fenced code block: ``` ---
            if lineStart && c == "`" {
                let remaining = source[index...]
                if remaining.hasPrefix("```") {
                    let start = index
                    // Consume the opening fence line
                    while index < source.endIndex && source[index] != "\n" {
                        index = source.index(after: index)
                    }
                    // Mark the opening fence line
                    tokens.append(HighlightToken(range: start..<index, type: .comment))

                    // Skip newline
                    if index < source.endIndex {
                        index = source.index(after: index)
                    }

                    // Find closing ```
                    while index < source.endIndex {
                        // Check if line starts with ```
                        var checkIdx = index
                        // Skip leading whitespace
                        while checkIdx < source.endIndex && (source[checkIdx] == " " || source[checkIdx] == "\t") {
                            checkIdx = source.index(after: checkIdx)
                        }
                        if source[checkIdx...].hasPrefix("```") {
                            let closeStart = checkIdx
                            // Consume the closing fence line
                            while checkIdx < source.endIndex && source[checkIdx] != "\n" {
                                checkIdx = source.index(after: checkIdx)
                            }
                            tokens.append(HighlightToken(range: closeStart..<checkIdx, type: .comment))
                            index = checkIdx
                            break
                        }
                        // Skip to next line
                        while index < source.endIndex && source[index] != "\n" {
                            index = source.index(after: index)
                        }
                        if index < source.endIndex {
                            index = source.index(after: index) // skip \n
                        }
                    }
                    lineStart = true
                    continue
                }
            }

            // --- Horizontal rule: ---, ***, ___ (at line start, 3+ chars) ---
            if lineStart && (c == "-" || c == "*" || c == "_") {
                let ruleChar = c
                var count = 0
                var checkIdx = index
                var onlyRuleChars = true
                while checkIdx < source.endIndex && source[checkIdx] != "\n" {
                    if source[checkIdx] == ruleChar || source[checkIdx] == " " {
                        if source[checkIdx] == ruleChar {
                            count += 1
                        }
                    } else {
                        onlyRuleChars = false
                        break
                    }
                    checkIdx = source.index(after: checkIdx)
                }
                if onlyRuleChars && count >= 3 {
                    let start = index
                    index = checkIdx
                    tokens.append(HighlightToken(range: start..<index, type: .comment))
                    lineStart = false
                    continue
                }
            }

            // --- Heading: # at line start ---
            if lineStart && c == "#" {
                let start = index
                while index < source.endIndex && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .keyword))
                lineStart = false
                continue
            }

            // --- Blockquote: > at line start ---
            if lineStart && c == ">" {
                let start = index
                index = source.index(after: index)
                // Include the space after >
                if index < source.endIndex && source[index] == " " {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .keyword))
                lineStart = false
                continue
            }

            // --- List marker: - or * at line start (not horizontal rule) ---
            if lineStart && (c == "-" || c == "*" || c == "+") {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == " " {
                    let start = index
                    index = source.index(after: next) // skip marker and space
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    lineStart = false
                    continue
                }
            }

            // --- Numbered list marker: digits followed by . or ) at line start ---
            if lineStart && c.isNumber {
                let start = index
                var numIdx = index
                while numIdx < source.endIndex && source[numIdx].isNumber {
                    numIdx = source.index(after: numIdx)
                }
                if numIdx < source.endIndex && (source[numIdx] == "." || source[numIdx] == ")") {
                    let afterDot = source.index(after: numIdx)
                    if afterDot < source.endIndex && source[afterDot] == " " {
                        index = source.index(after: afterDot)
                        tokens.append(HighlightToken(range: start..<index, type: .keyword))
                        lineStart = false
                        continue
                    }
                }
            }

            lineStart = false

            // Skip leading whitespace for line-start checks
            if c == " " || c == "\t" {
                index = source.index(after: index)
                // Don't reset lineStart so indented markers still work
                continue
            }

            // --- Inline code: `text` ---
            if c == "`" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex && source[index] != "`" && source[index] != "\n" {
                    index = source.index(after: index)
                }
                if index < source.endIndex && source[index] == "`" {
                    index = source.index(after: index) // skip closing `
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Bold: **text** ---
            if c == "*" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "*" {
                    let start = index
                    index = source.index(after: next) // skip opening **
                    // Find closing **
                    while index < source.endIndex {
                        if source[index] == "*" {
                            let nextStar = source.index(after: index)
                            if nextStar < source.endIndex && source[nextStar] == "*" {
                                index = source.index(after: nextStar) // skip closing **
                                break
                            }
                        }
                        if source[index] == "\n" {
                            break
                        }
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                }

                // --- Italic: *text* ---
                let start = index
                index = source.index(after: index) // skip opening *
                while index < source.endIndex && source[index] != "*" && source[index] != "\n" {
                    index = source.index(after: index)
                }
                if index < source.endIndex && source[index] == "*" {
                    index = source.index(after: index) // skip closing *
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Link: [text](url) ---
            if c == "[" {
                let bracketStart = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: bracketStart..<index, type: .punctuation))

                // Find closing ]
                let textStart = index
                while index < source.endIndex && source[index] != "]" && source[index] != "\n" {
                    index = source.index(after: index)
                }
                if index > textStart {
                    tokens.append(HighlightToken(range: textStart..<index, type: .plain))
                }

                if index < source.endIndex && source[index] == "]" {
                    let closeBracket = index
                    index = source.index(after: index)
                    tokens.append(HighlightToken(range: closeBracket..<index, type: .punctuation))

                    // Check for (url)
                    if index < source.endIndex && source[index] == "(" {
                        let parenStart = index
                        index = source.index(after: index)
                        tokens.append(HighlightToken(range: parenStart..<index, type: .punctuation))

                        let urlStart = index
                        while index < source.endIndex && source[index] != ")" && source[index] != "\n" {
                            index = source.index(after: index)
                        }
                        if index > urlStart {
                            tokens.append(HighlightToken(range: urlStart..<index, type: .string))
                        }

                        if index < source.endIndex && source[index] == ")" {
                            let parenEnd = index
                            index = source.index(after: index)
                            tokens.append(HighlightToken(range: parenEnd..<index, type: .punctuation))
                        }
                    }
                }
                continue
            }

            // --- Image: ![alt](url) ---
            if c == "!" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "[" {
                    let bangStart = index
                    index = source.index(after: index)
                    tokens.append(HighlightToken(range: bangStart..<index, type: .punctuation))
                    // The [ will be handled in the next iteration
                    continue
                }
            }

            // --- Anything else ---
            index = source.index(after: index)
        }

        return tokens
    }
}
