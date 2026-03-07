import Foundation

struct GoGrammar: SyntaxGrammar {
    static let languageID = "go"

    // MARK: - Keyword & builtin sets

    private static let keywords: Set<String> = [
        "break", "case", "chan", "const", "continue",
        "default", "defer", "else", "fallthrough", "for",
        "func", "go", "goto", "if", "import",
        "interface", "map", "package", "range", "return",
        "select", "struct", "switch", "type", "var",
        "true", "false", "nil", "iota",
    ]

    private static let builtinTypes: Set<String> = [
        "bool", "byte",
        "complex64", "complex128",
        "error",
        "float32", "float64",
        "int", "int8", "int16", "int32", "int64",
        "rune", "string",
        "uint", "uint8", "uint16", "uint32", "uint64", "uintptr",
        "any", "comparable",
    ]

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let chars = Array(source)
        let count = chars.count
        var i = 0

        // Map character‐array indices back to String.Index
        // Build the mapping once so range construction is O(1).
        var stringIndices: [String.Index] = []
        stringIndices.reserveCapacity(count + 1)
        var si = source.startIndex
        for _ in 0..<count {
            stringIndices.append(si)
            si = source.index(after: si)
        }
        stringIndices.append(source.endIndex)

        func makeRange(_ start: Int, _ end: Int) -> Range<String.Index> {
            stringIndices[start]..<stringIndices[end]
        }

        func emit(_ start: Int, _ end: Int, _ type: TokenType) {
            guard end > start else { return }
            tokens.append(HighlightToken(range: makeRange(start, end), type: type))
        }

        while i < count {
            let c = chars[i]

            // ── Line comment ──
            if c == "/" && i + 1 < count && chars[i + 1] == "/" {
                let start = i
                i += 2
                while i < count && chars[i] != "\n" {
                    i += 1
                }
                emit(start, i, .comment)
                continue
            }

            // ── Block comment ──
            if c == "/" && i + 1 < count && chars[i + 1] == "*" {
                let start = i
                i += 2
                var closed = false
                while i + 1 < count {
                    if chars[i] == "*" && chars[i + 1] == "/" {
                        i += 2
                        closed = true
                        break
                    }
                    i += 1
                }
                if !closed {
                    i = count
                }
                emit(start, i, .comment)
                continue
            }

            // ── Double‐quoted string ──
            if c == "\"" {
                let start = i
                i += 1
                while i < count && chars[i] != "\"" && chars[i] != "\n" {
                    if chars[i] == "\\" && i + 1 < count {
                        i += 2
                    } else {
                        i += 1
                    }
                }
                if i < count && chars[i] == "\"" {
                    i += 1
                }
                emit(start, i, .string)
                continue
            }

            // ── Raw string (backtick) ──
            if c == "`" {
                let start = i
                i += 1
                while i < count && chars[i] != "`" {
                    i += 1
                }
                if i < count {
                    i += 1
                }
                emit(start, i, .string)
                continue
            }

            // ── Rune literal ──
            if c == "'" {
                let start = i
                i += 1
                if i < count && chars[i] == "\\" {
                    i += 1
                    if i < count { i += 1 }
                } else if i < count && chars[i] != "'" {
                    i += 1
                }
                if i < count && chars[i] == "'" {
                    i += 1
                }
                emit(start, i, .string)
                continue
            }

            // ── Numbers ──
            if c.isNumber || (c == "." && i + 1 < count && chars[i + 1].isNumber) {
                let start = i

                if c == "0" && i + 1 < count {
                    let next = chars[i + 1]

                    // Hex
                    if next == "x" || next == "X" {
                        i += 2
                        while i < count && (chars[i].isHexDigit || chars[i] == "_") {
                            i += 1
                        }
                        // Optional imaginary suffix
                        if i < count && chars[i] == "i" { i += 1 }
                        emit(start, i, .number)
                        continue
                    }

                    // Binary
                    if next == "b" || next == "B" {
                        i += 2
                        while i < count && (chars[i] == "0" || chars[i] == "1" || chars[i] == "_") {
                            i += 1
                        }
                        if i < count && chars[i] == "i" { i += 1 }
                        emit(start, i, .number)
                        continue
                    }

                    // Octal
                    if next == "o" || next == "O" {
                        i += 2
                        while i < count && ((chars[i] >= "0" && chars[i] <= "7") || chars[i] == "_") {
                            i += 1
                        }
                        if i < count && chars[i] == "i" { i += 1 }
                        emit(start, i, .number)
                        continue
                    }
                }

                // Decimal integer / float
                while i < count && (chars[i].isNumber || chars[i] == "_") {
                    i += 1
                }
                // Fractional part
                if i < count && chars[i] == "." && (i + 1 >= count || chars[i + 1] != ".") {
                    i += 1
                    while i < count && (chars[i].isNumber || chars[i] == "_") {
                        i += 1
                    }
                }
                // Exponent
                if i < count && (chars[i] == "e" || chars[i] == "E") {
                    i += 1
                    if i < count && (chars[i] == "+" || chars[i] == "-") {
                        i += 1
                    }
                    while i < count && (chars[i].isNumber || chars[i] == "_") {
                        i += 1
                    }
                }
                // Imaginary suffix
                if i < count && chars[i] == "i" { i += 1 }
                emit(start, i, .number)
                continue
            }

            // ── Identifiers / keywords / types / function calls ──
            if c.isIdentifierStart {
                let start = i
                i += 1
                while i < count && chars[i].isIdentifierContinue {
                    i += 1
                }
                let word = String(chars[start..<i])

                // Skip whitespace to peek for '(' (function call detection)
                var peek = i
                while peek < count && chars[peek] == " " {
                    peek += 1
                }
                let followedByParen = peek < count && chars[peek] == "("

                if keywords.contains(word) {
                    emit(start, i, .keyword)
                } else if builtinTypes.contains(word) {
                    emit(start, i, .type)
                } else if word.first?.isUppercase == true {
                    // Uppercase identifiers are treated as types
                    emit(start, i, .type)
                } else if followedByParen {
                    emit(start, i, .functionCall)
                } else {
                    emit(start, i, .plain)
                }
                continue
            }

            // ── Short variable declaration :=  ──
            if c == ":" && i + 1 < count && chars[i + 1] == "=" {
                emit(i, i + 2, .operator_)
                i += 2
                continue
            }

            // ── Operators (multi‐char first, then single‐char) ──
            if c.isGoOperator {
                let start = i

                // Three‐character operators
                if i + 2 < count {
                    let three = String(chars[i...i+2])
                    if three == "<<=" || three == ">>=" || three == "&^=" {
                        i += 3
                        emit(start, i, .operator_)
                        continue
                    }
                }

                // Two‐character operators
                if i + 1 < count {
                    let two = String(chars[i...i+1])
                    if twoCharOperators.contains(two) {
                        i += 2
                        emit(start, i, .operator_)
                        continue
                    }
                }

                // Single‐character operator
                i += 1
                emit(start, i, .operator_)
                continue
            }

            // ── Ellipsis ... (variadic) ──
            if c == "." && i + 2 < count && chars[i + 1] == "." && chars[i + 2] == "." {
                emit(i, i + 3, .operator_)
                i += 3
                continue
            }

            // ── Punctuation ──
            if c.isGoPunctuation {
                emit(i, i + 1, .punctuation)
                i += 1
                continue
            }

            // ── Whitespace and anything else ──
            i += 1
        }

        return tokens
    }

    // MARK: - Operator tables

    private static let twoCharOperators: Set<String> = [
        "+=", "-=", "*=", "/=", "%=",
        "&=", "|=", "^=",
        "<<", ">>", "&^",
        "&&", "||",
        "<-",
        "++", "--",
        "==", "!=", "<=", ">=",
    ]
}

// MARK: - Character helpers

private extension Character {
    var isIdentifierStart: Bool {
        self.isLetter || self == "_"
    }

    var isIdentifierContinue: Bool {
        self.isLetter || self.isNumber || self == "_"
    }

    var isGoOperator: Bool {
        switch self {
        case "+", "-", "*", "/", "%",
             "&", "|", "^", "~",
             "<", ">", "=", "!":
            return true
        default:
            return false
        }
    }

    var isGoPunctuation: Bool {
        switch self {
        case "(", ")", "[", "]", "{", "}",
             ",", ";", ".", ":":
            return true
        default:
            return false
        }
    }
}
