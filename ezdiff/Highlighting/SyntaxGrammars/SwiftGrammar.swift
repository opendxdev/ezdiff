import Foundation

struct SwiftGrammar: SyntaxGrammar {

    static let languageID = "swift"

    // MARK: - Keywords

    private static let keywords: Set<String> = [
        "func", "var", "let", "class", "struct", "enum", "protocol",
        "import", "return", "if", "else", "guard", "switch", "case",
        "for", "while", "repeat", "do", "try", "catch", "throw", "throws",
        "break", "continue", "fallthrough", "defer", "where", "in", "is", "as",
        "nil", "true", "false", "self", "Self", "super",
        "init", "deinit", "extension", "subscript", "operator", "precedencegroup",
        "typealias", "associatedtype", "static", "private", "public", "internal",
        "fileprivate", "open", "final", "override", "required", "convenience",
        "mutating", "nonmutating", "lazy", "weak", "unowned", "inout",
        "some", "any", "async", "await", "actor", "nonisolated", "isolated",
        "sending", "consuming", "borrowing", "macro",
    ]

    private static let operatorChars: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "!", "<", ">", "&", "|", "^", "~", "?",
    ]

    private static let punctuationChars: Set<Character> = [
        "(", ")", "{", "}", "[", "]", ",", ";", ":", ".",
    ]

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let chars = source
        var index = chars.startIndex

        while index < chars.endIndex {
            let c = chars[index]

            // --- Single-line comment ---
            if c == "/" && chars.index(after: index) < chars.endIndex && chars[chars.index(after: index)] == "/" {
                let start = index
                // Consume until end of line
                while index < chars.endIndex && chars[index] != "\n" {
                    index = chars.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                continue
            }

            // --- Multi-line comment (with nesting) ---
            if c == "/" && chars.index(after: index) < chars.endIndex && chars[chars.index(after: index)] == "*" {
                let start = index
                index = chars.index(index, offsetBy: 2) // skip /*
                var depth = 1
                while index < chars.endIndex && depth > 0 {
                    let next = chars.index(after: index)
                    if chars[index] == "/" && next < chars.endIndex && chars[next] == "*" {
                        depth += 1
                        index = chars.index(index, offsetBy: 2)
                    } else if chars[index] == "*" && next < chars.endIndex && chars[next] == "/" {
                        depth -= 1
                        index = chars.index(index, offsetBy: 2)
                    } else {
                        index = chars.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                continue
            }

            // --- Multi-line string (triple-quoted) ---
            if c == "\"" {
                let next1 = chars.index(after: index)
                let next2 = next1 < chars.endIndex ? chars.index(after: next1) : chars.endIndex
                if next1 < chars.endIndex && next2 < chars.endIndex
                    && chars[next1] == "\"" && chars[next2] == "\""
                {
                    let start = index
                    index = chars.index(index, offsetBy: 3) // skip """
                    // Find closing """
                    while index < chars.endIndex {
                        if chars[index] == "\\" {
                            // skip escaped character
                            let afterBackslash = chars.index(after: index)
                            if afterBackslash < chars.endIndex {
                                index = chars.index(after: afterBackslash)
                            } else {
                                index = chars.index(after: index)
                            }
                        } else if chars[index] == "\"" {
                            let q1 = chars.index(after: index)
                            let q2 = q1 < chars.endIndex ? chars.index(after: q1) : chars.endIndex
                            if q1 < chars.endIndex && q2 <= chars.endIndex
                                && chars[q1] == "\""
                                && q2 < chars.endIndex && chars[q2] == "\""
                            {
                                // Check it's not four or more quotes in a row (edge case)
                                index = chars.index(index, offsetBy: 3)
                                break
                            } else {
                                index = chars.index(after: index)
                            }
                        } else {
                            index = chars.index(after: index)
                        }
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .string))
                    continue
                }
            }

            // --- Single-line string ---
            if c == "\"" {
                let start = index
                index = chars.index(after: index) // skip opening "
                while index < chars.endIndex {
                    if chars[index] == "\\" {
                        // skip escaped character
                        let afterBackslash = chars.index(after: index)
                        if afterBackslash < chars.endIndex {
                            index = chars.index(after: afterBackslash)
                        } else {
                            index = chars.index(after: index)
                        }
                    } else if chars[index] == "\"" {
                        index = chars.index(after: index) // skip closing "
                        break
                    } else if chars[index] == "\n" {
                        // unterminated string at end of line
                        break
                    } else {
                        index = chars.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Numbers ---
            if c.isNumber || (c == "." && index < chars.endIndex && {
                let next = chars.index(after: index)
                return next < chars.endIndex && chars[next].isNumber
            }()) {
                let start = index

                if c == "0" {
                    let next = chars.index(after: index)
                    if next < chars.endIndex {
                        let prefix = chars[next]
                        if prefix == "x" || prefix == "X" {
                            // Hex literal
                            index = chars.index(after: next)
                            while index < chars.endIndex && (chars[index].isHexDigit || chars[index] == "_") {
                                index = chars.index(after: index)
                            }
                            tokens.append(HighlightToken(range: start..<index, type: .number))
                            continue
                        } else if prefix == "b" || prefix == "B" {
                            // Binary literal
                            index = chars.index(after: next)
                            while index < chars.endIndex && (chars[index] == "0" || chars[index] == "1" || chars[index] == "_") {
                                index = chars.index(after: index)
                            }
                            tokens.append(HighlightToken(range: start..<index, type: .number))
                            continue
                        } else if prefix == "o" || prefix == "O" {
                            // Octal literal
                            index = chars.index(after: next)
                            while index < chars.endIndex && ((chars[index] >= "0" && chars[index] <= "7") || chars[index] == "_") {
                                index = chars.index(after: index)
                            }
                            tokens.append(HighlightToken(range: start..<index, type: .number))
                            continue
                        }
                    }
                }

                // Decimal integer or float
                while index < chars.endIndex && (chars[index].isNumber || chars[index] == "_") {
                    index = chars.index(after: index)
                }
                // Check for fractional part
                if index < chars.endIndex && chars[index] == "." {
                    let afterDot = chars.index(after: index)
                    if afterDot < chars.endIndex && chars[afterDot].isNumber {
                        index = chars.index(after: index) // skip "."
                        while index < chars.endIndex && (chars[index].isNumber || chars[index] == "_") {
                            index = chars.index(after: index)
                        }
                    }
                }
                // Check for exponent
                if index < chars.endIndex && (chars[index] == "e" || chars[index] == "E") {
                    let afterE = chars.index(after: index)
                    if afterE < chars.endIndex {
                        var expIndex = afterE
                        if chars[expIndex] == "+" || chars[expIndex] == "-" {
                            expIndex = chars.index(after: expIndex)
                        }
                        if expIndex < chars.endIndex && chars[expIndex].isNumber {
                            index = expIndex
                            while index < chars.endIndex && (chars[index].isNumber || chars[index] == "_") {
                                index = chars.index(after: index)
                            }
                        }
                    }
                }

                tokens.append(HighlightToken(range: start..<index, type: .number))
                continue
            }

            // --- Identifiers, keywords, types, function calls ---
            if c.isLetter || c == "_" {
                let start = index
                while index < chars.endIndex && (chars[index].isLetter || chars[index].isNumber || chars[index] == "_") {
                    index = chars.index(after: index)
                }
                let word = String(chars[start..<index])

                // Check if it's a keyword
                if keywords.contains(word) {
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                }

                // Skip whitespace to see if followed by (
                var lookahead = index
                while lookahead < chars.endIndex && (chars[lookahead] == " " || chars[lookahead] == "\t") {
                    lookahead = chars.index(after: lookahead)
                }

                if lookahead < chars.endIndex && chars[lookahead] == "(" {
                    tokens.append(HighlightToken(range: start..<index, type: .functionCall))
                    continue
                }

                // Check if it's a type (starts with uppercase)
                if let first = word.first, first.isUppercase {
                    tokens.append(HighlightToken(range: start..<index, type: .type))
                    continue
                }

                // Plain identifier
                tokens.append(HighlightToken(range: start..<index, type: .plain))
                continue
            }

            // --- Hash directives / compiler directives ---
            if c == "#" {
                let start = index
                index = chars.index(after: index)
                while index < chars.endIndex && (chars[index].isLetter || chars[index].isNumber || chars[index] == "_") {
                    index = chars.index(after: index)
                }
                if index > chars.index(after: start) {
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                } else {
                    tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                }
                continue
            }

            // --- @ attributes ---
            if c == "@" {
                let start = index
                index = chars.index(after: index)
                while index < chars.endIndex && (chars[index].isLetter || chars[index].isNumber || chars[index] == "_") {
                    index = chars.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .keyword))
                continue
            }

            // --- Operators ---
            if operatorChars.contains(c) {
                let start = index
                while index < chars.endIndex && operatorChars.contains(chars[index]) {
                    index = chars.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .operator_))
                continue
            }

            // --- Punctuation ---
            if punctuationChars.contains(c) {
                let start = index
                index = chars.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Whitespace and other characters: skip ---
            index = chars.index(after: index)
        }

        return tokens
    }
}
