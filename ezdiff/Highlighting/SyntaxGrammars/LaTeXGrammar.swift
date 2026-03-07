import Foundation

struct LaTeXGrammar: SyntaxGrammar {

    static let languageID = "latex"

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex

        while index < source.endIndex {
            let c = source[index]

            // --- Comment: % to end of line ---
            if c == "%" {
                let start = index
                while index < source.endIndex && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                continue
            }

            // --- Math display: $$ ... $$ ---
            if c == "$" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "$" {
                    let start = index
                    index = source.index(after: next) // skip $$
                    // Find closing $$
                    while index < source.endIndex {
                        if source[index] == "$" {
                            let afterDollar = source.index(after: index)
                            if afterDollar < source.endIndex && source[afterDollar] == "$" {
                                index = source.index(after: afterDollar)
                                break
                            }
                        }
                        if source[index] == "\\" {
                            let afterBackslash = source.index(after: index)
                            if afterBackslash < source.endIndex {
                                index = source.index(after: afterBackslash)
                            } else {
                                index = source.index(after: index)
                            }
                        } else {
                            index = source.index(after: index)
                        }
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .latexMathBlock))
                    continue
                }

                // --- Math inline: $ ... $ ---
                let start = index
                index = source.index(after: index) // skip opening $
                while index < source.endIndex {
                    if source[index] == "$" {
                        index = source.index(after: index) // skip closing $
                        break
                    }
                    if source[index] == "\\" {
                        let afterBackslash = source.index(after: index)
                        if afterBackslash < source.endIndex {
                            index = source.index(after: afterBackslash)
                        } else {
                            index = source.index(after: index)
                        }
                    } else if source[index] == "\n" {
                        // Inline math doesn't span lines typically, but be lenient
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .latexMathInline))
                continue
            }

            // --- Math display: \[ ... \] ---
            if c == "\\" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "[" {
                    let start = index
                    index = source.index(after: next) // skip \[
                    // Find \]
                    while index < source.endIndex {
                        if source[index] == "\\" {
                            let afterBackslash = source.index(after: index)
                            if afterBackslash < source.endIndex && source[afterBackslash] == "]" {
                                index = source.index(after: afterBackslash)
                                break
                            }
                            if afterBackslash < source.endIndex {
                                index = source.index(after: afterBackslash)
                            } else {
                                index = source.index(after: index)
                            }
                        } else {
                            index = source.index(after: index)
                        }
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .latexMathBlock))
                    continue
                }

                // --- Math inline: \( ... \) ---
                if next < source.endIndex && source[next] == "(" {
                    let start = index
                    index = source.index(after: next) // skip \(
                    // Find \)
                    while index < source.endIndex {
                        if source[index] == "\\" {
                            let afterBackslash = source.index(after: index)
                            if afterBackslash < source.endIndex && source[afterBackslash] == ")" {
                                index = source.index(after: afterBackslash)
                                break
                            }
                            if afterBackslash < source.endIndex {
                                index = source.index(after: afterBackslash)
                            } else {
                                index = source.index(after: index)
                            }
                        } else {
                            index = source.index(after: index)
                        }
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .latexMathInline))
                    continue
                }

                // --- Environment: \begin{env} and \end{env} ---
                let remaining = source[index...]
                if remaining.hasPrefix("\\begin{") || remaining.hasPrefix("\\end{") {
                    let start = index
                    // Skip \begin or \end
                    if remaining.hasPrefix("\\begin{") {
                        index = source.index(index, offsetBy: 6)
                    } else {
                        index = source.index(index, offsetBy: 4)
                    }
                    // Skip {env}
                    if index < source.endIndex && source[index] == "{" {
                        while index < source.endIndex && source[index] != "}" {
                            index = source.index(after: index)
                        }
                        if index < source.endIndex {
                            index = source.index(after: index) // skip }
                        }
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .latexCommand))
                    continue
                }

                // --- Command: \command ---
                if next < source.endIndex && (source[next].isLetter || source[next] == "@") {
                    let start = index
                    index = source.index(after: index) // skip backslash
                    while index < source.endIndex && (source[index].isLetter || source[index] == "@" || source[index] == "*") {
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .latexCommand))
                    continue
                }

                // --- Escaped character: \# \$ \& etc. ---
                if next < source.endIndex {
                    let start = index
                    index = source.index(after: next)
                    tokens.append(HighlightToken(range: start..<index, type: .latexCommand))
                    continue
                }
            }

            // --- Curly braces ---
            if c == "{" || c == "}" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Square brackets (optional arguments) ---
            if c == "[" || c == "]" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Numbers ---
            if c.isNumber {
                let start = index
                while index < source.endIndex && (source[index].isNumber || source[index] == ".") {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .number))
                continue
            }

            // --- Anything else ---
            index = source.index(after: index)
        }

        return tokens
    }
}
