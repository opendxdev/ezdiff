import Foundation

struct PythonGrammar: SyntaxGrammar {

    static let languageID: String = "python"

    // MARK: - Keyword set

    private static let keywords: Set<String> = [
        "False", "None", "True",
        "and", "as", "assert", "async", "await",
        "break",
        "case", "class", "continue",
        "def", "del",
        "elif", "else", "except",
        "finally", "for", "from",
        "global",
        "if", "import", "in", "is",
        "lambda",
        "match",
        "nonlocal", "not",
        "or",
        "pass",
        "raise", "return",
        "try",
        "while", "with",
        "yield",
    ]

    // MARK: - Helpers

    private static func isIdentifierStart(_ c: Character) -> Bool {
        c.isLetter || c == "_"
    }

    private static func isIdentifierContinue(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "_"
    }

    private static func isOperatorChar(_ c: Character) -> Bool {
        "+-*/%&|^~<>=!@".contains(c)
    }

    private static func isPunctuation(_ c: Character) -> Bool {
        "()[]{}:;,.\\".contains(c)
    }

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let str = source
        var i = str.startIndex

        while i < str.endIndex {
            let c = str[i]

            // -----------------------------------------------------------
            // 1. Comments: # to end of line
            // -----------------------------------------------------------
            if c == "#" {
                let start = i
                while i < str.endIndex && str[i] != "\n" {
                    i = str.index(after: i)
                }
                tokens.append(HighlightToken(range: start..<i, type: .comment))
                continue
            }

            // -----------------------------------------------------------
            // 2. Strings (including triple-quoted, f/r/b/u prefixes)
            // -----------------------------------------------------------
            if c == "\"" || c == "'" ||
                ((c == "f" || c == "F" || c == "r" || c == "R" ||
                  c == "b" || c == "B" || c == "u" || c == "U") &&
                 str.index(after: i) < str.endIndex &&
                 (str[str.index(after: i)] == "\"" || str[str.index(after: i)] == "'")) ||
                // Two-char prefixes: fr, rf, br, rb, etc.
                ((c == "f" || c == "F" || c == "r" || c == "R" ||
                  c == "b" || c == "B") &&
                 str.index(after: i) < str.endIndex &&
                 (str[str.index(after: i)] == "r" || str[str.index(after: i)] == "R" ||
                  str[str.index(after: i)] == "b" || str[str.index(after: i)] == "B" ||
                  str[str.index(after: i)] == "f" || str[str.index(after: i)] == "F") &&
                 str.index(i, offsetBy: 2, limitedBy: str.endIndex) != nil &&
                 str.index(i, offsetBy: 2, limitedBy: str.endIndex).map({ $0 < str.endIndex && (str[$0] == "\"" || str[$0] == "'") }) == true) {

                let start = i

                // Advance past prefix characters to find the quote char
                var quoteStart = i
                if c != "\"" && c != "'" {
                    quoteStart = str.index(after: quoteStart)
                    if quoteStart < str.endIndex && str[quoteStart] != "\"" && str[quoteStart] != "'" {
                        quoteStart = str.index(after: quoteStart)
                    }
                }

                guard quoteStart < str.endIndex else {
                    i = str.index(after: i)
                    continue
                }

                let quoteChar = str[quoteStart]
                let afterQuote = str.index(after: quoteStart)

                // Check for triple-quoted string
                let isTriple: Bool
                if afterQuote < str.endIndex &&
                    str.index(after: afterQuote) < str.endIndex &&
                    str[afterQuote] == quoteChar &&
                    str[str.index(after: afterQuote)] == quoteChar {
                    isTriple = true
                } else {
                    isTriple = false
                }

                if isTriple {
                    // Advance past the opening triple quote
                    i = str.index(str.index(after: afterQuote), offsetBy: 1, limitedBy: str.endIndex) ?? str.endIndex
                    // Find closing triple quote
                    var found = false
                    while i < str.endIndex {
                        if str[i] == "\\" {
                            // Skip escaped character
                            i = str.index(after: i)
                            if i < str.endIndex {
                                i = str.index(after: i)
                            }
                            continue
                        }
                        if str[i] == quoteChar {
                            let next1 = str.index(after: i)
                            if next1 < str.endIndex && str[next1] == quoteChar {
                                let next2 = str.index(after: next1)
                                if next2 < str.endIndex && str[next2] == quoteChar {
                                    i = str.index(after: next2)
                                    found = true
                                    break
                                }
                            }
                        }
                        i = str.index(after: i)
                    }
                    if !found {
                        i = str.endIndex
                    }
                } else {
                    // Single-quoted string: advance past opening quote
                    i = str.index(after: quoteStart)
                    while i < str.endIndex && str[i] != quoteChar && str[i] != "\n" {
                        if str[i] == "\\" {
                            i = str.index(after: i)
                            if i < str.endIndex {
                                i = str.index(after: i)
                            }
                            continue
                        }
                        i = str.index(after: i)
                    }
                    if i < str.endIndex && str[i] == quoteChar {
                        i = str.index(after: i)
                    }
                }

                tokens.append(HighlightToken(range: start..<i, type: .string))
                continue
            }

            // -----------------------------------------------------------
            // 3. Numbers: integers, floats, hex, octal, binary, complex
            // -----------------------------------------------------------
            if c.isNumber || (c == "." && {
                let next = str.index(after: i)
                return next < str.endIndex && str[next].isNumber
            }()) {
                let start = i

                if c == "0" {
                    let next = str.index(after: i)
                    if next < str.endIndex {
                        let nc = str[next]
                        if nc == "x" || nc == "X" {
                            // Hex
                            i = str.index(after: next)
                            while i < str.endIndex && (str[i].isHexDigit || str[i] == "_") {
                                i = str.index(after: i)
                            }
                            // Complex suffix
                            if i < str.endIndex && (str[i] == "j" || str[i] == "J") {
                                i = str.index(after: i)
                            }
                            tokens.append(HighlightToken(range: start..<i, type: .number))
                            continue
                        } else if nc == "b" || nc == "B" {
                            // Binary
                            i = str.index(after: next)
                            while i < str.endIndex && (str[i] == "0" || str[i] == "1" || str[i] == "_") {
                                i = str.index(after: i)
                            }
                            if i < str.endIndex && (str[i] == "j" || str[i] == "J") {
                                i = str.index(after: i)
                            }
                            tokens.append(HighlightToken(range: start..<i, type: .number))
                            continue
                        } else if nc == "o" || nc == "O" {
                            // Octal
                            i = str.index(after: next)
                            while i < str.endIndex && ((str[i] >= "0" && str[i] <= "7") || str[i] == "_") {
                                i = str.index(after: i)
                            }
                            if i < str.endIndex && (str[i] == "j" || str[i] == "J") {
                                i = str.index(after: i)
                            }
                            tokens.append(HighlightToken(range: start..<i, type: .number))
                            continue
                        }
                    }
                }

                // Decimal integer / float
                while i < str.endIndex && (str[i].isNumber || str[i] == "_") {
                    i = str.index(after: i)
                }
                // Fractional part
                if i < str.endIndex && str[i] == "." {
                    i = str.index(after: i)
                    while i < str.endIndex && (str[i].isNumber || str[i] == "_") {
                        i = str.index(after: i)
                    }
                }
                // Exponent
                if i < str.endIndex && (str[i] == "e" || str[i] == "E") {
                    i = str.index(after: i)
                    if i < str.endIndex && (str[i] == "+" || str[i] == "-") {
                        i = str.index(after: i)
                    }
                    while i < str.endIndex && (str[i].isNumber || str[i] == "_") {
                        i = str.index(after: i)
                    }
                }
                // Complex suffix
                if i < str.endIndex && (str[i] == "j" || str[i] == "J") {
                    i = str.index(after: i)
                }

                tokens.append(HighlightToken(range: start..<i, type: .number))
                continue
            }

            // -----------------------------------------------------------
            // 4. Decorators: @identifier
            // -----------------------------------------------------------
            if c == "@" {
                let start = i
                i = str.index(after: i)
                while i < str.endIndex && (isIdentifierContinue(str[i]) || str[i] == ".") {
                    i = str.index(after: i)
                }
                if i > str.index(after: start) {
                    tokens.append(HighlightToken(range: start..<i, type: .keyword))
                } else {
                    // Lone @ is an operator (matrix multiply)
                    tokens.append(HighlightToken(range: start..<i, type: .operator_))
                }
                continue
            }

            // -----------------------------------------------------------
            // 5. Identifiers, keywords, types, function calls
            // -----------------------------------------------------------
            if isIdentifierStart(c) {
                let start = i
                i = str.index(after: i)
                while i < str.endIndex && isIdentifierContinue(str[i]) {
                    i = str.index(after: i)
                }
                let word = String(str[start..<i])

                // Before classifying, check for string prefixes that weren't
                // caught above (e.g. standalone f/r/b/u not followed by quote).
                // Those are just identifiers, handled normally below.

                if keywords.contains(word) {
                    tokens.append(HighlightToken(range: start..<i, type: .keyword))
                } else {
                    // Skip whitespace to check for function call
                    var peek = i
                    while peek < str.endIndex && str[peek] == " " {
                        peek = str.index(after: peek)
                    }
                    if peek < str.endIndex && str[peek] == "(" {
                        tokens.append(HighlightToken(range: start..<i, type: .functionCall))
                    } else if word.first?.isUppercase == true {
                        tokens.append(HighlightToken(range: start..<i, type: .type))
                    } else {
                        tokens.append(HighlightToken(range: start..<i, type: .plain))
                    }
                }
                continue
            }

            // -----------------------------------------------------------
            // 6. Operators (multi-character aware)
            // -----------------------------------------------------------
            if isOperatorChar(c) {
                let start = i
                i = str.index(after: i)
                // Consume consecutive operator characters to form
                // compound operators like ==, !=, <=, >=, <<, >>, **,
                // //, ->, +=, -=, etc.
                while i < str.endIndex && isOperatorChar(str[i]) {
                    i = str.index(after: i)
                }
                tokens.append(HighlightToken(range: start..<i, type: .operator_))
                continue
            }

            // -----------------------------------------------------------
            // 7. Punctuation
            // -----------------------------------------------------------
            if isPunctuation(c) {
                let start = i
                i = str.index(after: i)
                tokens.append(HighlightToken(range: start..<i, type: .punctuation))
                continue
            }

            // -----------------------------------------------------------
            // 8. Whitespace and anything else: skip
            // -----------------------------------------------------------
            i = str.index(after: i)
        }

        return tokens
    }
}
