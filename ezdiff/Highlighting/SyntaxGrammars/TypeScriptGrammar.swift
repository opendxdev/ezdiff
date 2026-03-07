import Foundation

struct TypeScriptGrammar: SyntaxGrammar {

    static let languageID: String = "typescript"

    // MARK: - Keywords

    private static let keywords: Set<String> = [
        // JavaScript keywords
        "break", "case", "catch", "class", "const", "continue", "debugger",
        "default", "delete", "do", "else", "export", "extends", "false",
        "finally", "for", "function", "if", "import", "in", "instanceof",
        "let", "new", "null", "of", "return", "super", "switch", "this",
        "throw", "true", "try", "typeof", "undefined", "var", "void",
        "while", "with", "yield", "async", "await", "from", "static",
        "get", "set",
        // TypeScript-specific keywords
        "interface", "type", "enum", "namespace", "readonly", "as",
        "keyof", "implements", "declare", "abstract", "module",
        "require", "asserts", "infer", "is", "never", "unknown", "any",
        "override", "satisfies",
    ]

    private static let operatorChars: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "!", "<", ">", "&", "|", "^", "~", "?", ":"
    ]

    private static let punctuationChars: Set<Character> = [
        "(", ")", "[", "]", "{", "}", ",", ";", "."
    ]

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let chars = Array(source)
        let count = chars.count
        var i = 0

        // Build a mapping from character offset to String.Index for range construction
        var indexMap: [Int: String.Index] = [:]
        var idx = source.startIndex
        for offset in 0..<count {
            indexMap[offset] = idx
            idx = source.index(after: idx)
        }
        indexMap[count] = source.endIndex

        func makeRange(_ start: Int, _ end: Int) -> Range<String.Index> {
            return indexMap[start]!..<indexMap[end]!
        }

        func isIdentStart(_ c: Character) -> Bool {
            return c.isLetter || c == "_" || c == "$"
        }

        func isIdentChar(_ c: Character) -> Bool {
            return c.isLetter || c.isNumber || c == "_" || c == "$"
        }

        while i < count {
            let c = chars[i]

            // --- Single-line comment: // ---
            if c == "/" && i + 1 < count && chars[i + 1] == "/" {
                let start = i
                i += 2
                while i < count && chars[i] != "\n" {
                    i += 1
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .comment))
                continue
            }

            // --- Multi-line comment: /* ... */ ---
            if c == "/" && i + 1 < count && chars[i + 1] == "*" {
                let start = i
                i += 2
                while i + 1 < count {
                    if chars[i] == "*" && chars[i + 1] == "/" {
                        i += 2
                        break
                    }
                    i += 1
                }
                if i <= count {
                    // Handle unterminated comment - consume rest of source
                    if i > count { i = count }
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .comment))
                continue
            }

            // --- Double-quoted string ---
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
                tokens.append(HighlightToken(range: makeRange(start, i), type: .string))
                continue
            }

            // --- Single-quoted string ---
            if c == "'" {
                let start = i
                i += 1
                while i < count && chars[i] != "'" && chars[i] != "\n" {
                    if chars[i] == "\\" && i + 1 < count {
                        i += 2
                    } else {
                        i += 1
                    }
                }
                if i < count && chars[i] == "'" {
                    i += 1
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .string))
                continue
            }

            // --- Template literal (backtick) ---
            if c == "`" {
                let start = i
                i += 1
                var depth = 0
                while i < count {
                    if chars[i] == "\\" && i + 1 < count {
                        i += 2
                        continue
                    }
                    if chars[i] == "$" && i + 1 < count && chars[i + 1] == "{" {
                        depth += 1
                        i += 2
                        continue
                    }
                    if chars[i] == "}" && depth > 0 {
                        depth -= 1
                        i += 1
                        continue
                    }
                    if chars[i] == "`" && depth == 0 {
                        i += 1
                        break
                    }
                    i += 1
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .string))
                continue
            }

            // --- Numbers ---
            if c.isNumber || (c == "." && i + 1 < count && chars[i + 1].isNumber) {
                let start = i
                // Hex: 0x...
                if c == "0" && i + 1 < count && (chars[i + 1] == "x" || chars[i + 1] == "X") {
                    i += 2
                    while i < count && chars[i].isHexDigit {
                        i += 1
                    }
                }
                // Binary: 0b...
                else if c == "0" && i + 1 < count && (chars[i + 1] == "b" || chars[i + 1] == "B") {
                    i += 2
                    while i < count && (chars[i] == "0" || chars[i] == "1") {
                        i += 1
                    }
                }
                // Octal: 0o...
                else if c == "0" && i + 1 < count && (chars[i + 1] == "o" || chars[i + 1] == "O") {
                    i += 2
                    while i < count && chars[i] >= "0" && chars[i] <= "7" {
                        i += 1
                    }
                }
                else {
                    // Decimal (with optional dot and exponent)
                    while i < count && chars[i].isNumber {
                        i += 1
                    }
                    if i < count && chars[i] == "." {
                        i += 1
                        while i < count && chars[i].isNumber {
                            i += 1
                        }
                    }
                    if i < count && (chars[i] == "e" || chars[i] == "E") {
                        i += 1
                        if i < count && (chars[i] == "+" || chars[i] == "-") {
                            i += 1
                        }
                        while i < count && chars[i].isNumber {
                            i += 1
                        }
                    }
                }
                // BigInt suffix
                if i < count && chars[i] == "n" {
                    i += 1
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .number))
                continue
            }

            // --- Identifiers, keywords, types, function calls ---
            if isIdentStart(c) {
                let start = i
                i += 1
                while i < count && isIdentChar(chars[i]) {
                    i += 1
                }
                let word = String(chars[start..<i])

                // Check if it's a function call: identifier followed by '('
                var j = i
                while j < count && chars[j] == " " {
                    j += 1
                }
                let isFollowedByParen = j < count && chars[j] == "("

                if keywords.contains(word) {
                    tokens.append(HighlightToken(range: makeRange(start, i), type: .keyword))
                } else if isFollowedByParen {
                    tokens.append(HighlightToken(range: makeRange(start, i), type: .functionCall))
                } else if word.first?.isUppercase == true {
                    tokens.append(HighlightToken(range: makeRange(start, i), type: .type))
                } else {
                    tokens.append(HighlightToken(range: makeRange(start, i), type: .plain))
                }
                continue
            }

            // --- Operators ---
            if operatorChars.contains(c) {
                let start = i
                i += 1
                // Consume consecutive operator characters
                while i < count && operatorChars.contains(chars[i]) {
                    i += 1
                }
                tokens.append(HighlightToken(range: makeRange(start, i), type: .operator_))
                continue
            }

            // --- Punctuation ---
            if punctuationChars.contains(c) {
                tokens.append(HighlightToken(range: makeRange(i, i + 1), type: .punctuation))
                i += 1
                continue
            }

            // --- Whitespace and other characters: skip ---
            i += 1
        }

        return tokens
    }
}
