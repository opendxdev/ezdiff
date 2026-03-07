import Foundation

struct JSONGrammar: SyntaxGrammar {

    static let languageID = "json"

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex

        while index < source.endIndex {
            let c = source[index]

            // --- Whitespace ---
            if c.isWhitespace {
                index = source.index(after: index)
                continue
            }

            // --- String (double-quoted) ---
            if c == "\"" {
                let start = index
                index = source.index(after: index) // skip opening "
                while index < source.endIndex {
                    if source[index] == "\\" {
                        let afterBackslash = source.index(after: index)
                        if afterBackslash < source.endIndex {
                            index = source.index(after: afterBackslash)
                        } else {
                            index = source.index(after: index)
                        }
                    } else if source[index] == "\"" {
                        index = source.index(after: index) // skip closing "
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                // Determine if this is a key (followed by :) or a value
                var lookahead = index
                while lookahead < source.endIndex && (source[lookahead] == " " || source[lookahead] == "\t" || source[lookahead] == "\n" || source[lookahead] == "\r") {
                    lookahead = source.index(after: lookahead)
                }
                if lookahead < source.endIndex && source[lookahead] == ":" {
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                } else {
                    tokens.append(HighlightToken(range: start..<index, type: .string))
                }
                continue
            }

            // --- Numbers ---
            if c.isNumber || c == "-" {
                // Check that - is followed by a digit
                if c == "-" {
                    let next = source.index(after: index)
                    guard next < source.endIndex && source[next].isNumber else {
                        // Not a number, treat as plain
                        let start = index
                        index = source.index(after: index)
                        tokens.append(HighlightToken(range: start..<index, type: .plain))
                        continue
                    }
                }
                let start = index
                if c == "-" {
                    index = source.index(after: index)
                }
                while index < source.endIndex && source[index].isNumber {
                    index = source.index(after: index)
                }
                // Fractional part
                if index < source.endIndex && source[index] == "." {
                    index = source.index(after: index)
                    while index < source.endIndex && source[index].isNumber {
                        index = source.index(after: index)
                    }
                }
                // Exponent
                if index < source.endIndex && (source[index] == "e" || source[index] == "E") {
                    index = source.index(after: index)
                    if index < source.endIndex && (source[index] == "+" || source[index] == "-") {
                        index = source.index(after: index)
                    }
                    while index < source.endIndex && source[index].isNumber {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .number))
                continue
            }

            // --- Booleans and null ---
            if c == "t" || c == "f" || c == "n" {
                let start = index
                // Try to match true, false, null
                let remaining = source[index...]
                if remaining.hasPrefix("true") {
                    index = source.index(index, offsetBy: 4)
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                } else if remaining.hasPrefix("false") {
                    index = source.index(index, offsetBy: 5)
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                } else if remaining.hasPrefix("null") {
                    index = source.index(index, offsetBy: 4)
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                }
                // Not a keyword, skip
                index = source.index(after: index)
                continue
            }

            // --- Punctuation: { } [ ] : , ---
            if c == "{" || c == "}" || c == "[" || c == "]" || c == ":" || c == "," {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Anything else ---
            index = source.index(after: index)
        }

        return tokens
    }
}
