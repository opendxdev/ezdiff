import Foundation

struct JavaScriptGrammar: SyntaxGrammar {
    static let languageID = "javascript"

    private static let keywords: Set<String> = [
        "function", "var", "let", "const", "if", "else", "for", "while", "do",
        "switch", "case", "break", "continue", "return", "throw", "try", "catch",
        "finally", "new", "delete", "typeof", "instanceof", "void", "in", "of",
        "class", "extends", "super", "this", "import", "export", "default", "from",
        "as", "async", "await", "yield", "static", "get", "set",
        "true", "false", "null", "undefined",
    ]

    private static let operators: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "<", ">", "!", "&", "|", "^", "~", "?", ":"
    ]

    private static let punctuation: Set<Character> = [
        "(", ")", "{", "}", "[", "]", ",", ";", "."
    ]

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let chars = source
        var i = chars.startIndex

        while i < chars.endIndex {
            let c = chars[i]

            // -----------------------------------------------------------
            // Single-line comment  //
            // -----------------------------------------------------------
            if c == "/" && chars.index(after: i) < chars.endIndex && chars[chars.index(after: i)] == "/" {
                let start = i
                i = chars.index(after: chars.index(after: i)) // skip //
                while i < chars.endIndex && chars[i] != "\n" {
                    i = chars.index(after: i)
                }
                tokens.append(HighlightToken(range: start..<i, type: .comment))
                continue
            }

            // -----------------------------------------------------------
            // Multi-line comment  /* ... */
            // -----------------------------------------------------------
            if c == "/" && chars.index(after: i) < chars.endIndex && chars[chars.index(after: i)] == "*" {
                let start = i
                i = chars.index(after: chars.index(after: i)) // skip /*
                while i < chars.endIndex {
                    if chars[i] == "*" && chars.index(after: i) < chars.endIndex && chars[chars.index(after: i)] == "/" {
                        i = chars.index(after: chars.index(after: i)) // skip */
                        break
                    }
                    i = chars.index(after: i)
                }
                tokens.append(HighlightToken(range: start..<i, type: .comment))
                continue
            }

            // -----------------------------------------------------------
            // Template literal  `...`  with ${...} interpolation
            // -----------------------------------------------------------
            if c == "`" {
                tokenizeTemplateLiteral(source: chars, index: &i, tokens: &tokens)
                continue
            }

            // -----------------------------------------------------------
            // String literals  '...'  and  "..."
            // -----------------------------------------------------------
            if c == "\"" || c == "'" {
                let quote = c
                let start = i
                i = chars.index(after: i) // skip opening quote
                while i < chars.endIndex && chars[i] != quote {
                    if chars[i] == "\\" && chars.index(after: i) < chars.endIndex {
                        i = chars.index(after: chars.index(after: i))
                    } else if chars[i] == "\n" {
                        // Unterminated string at newline
                        break
                    } else {
                        i = chars.index(after: i)
                    }
                }
                if i < chars.endIndex && chars[i] == quote {
                    i = chars.index(after: i) // skip closing quote
                }
                tokens.append(HighlightToken(range: start..<i, type: .string))
                continue
            }

            // -----------------------------------------------------------
            // Numbers: hex 0x, binary 0b, octal 0o, decimal, floats
            // -----------------------------------------------------------
            if c.isNumber || (c == "." && chars.index(after: i) < chars.endIndex && chars[chars.index(after: i)].isNumber) {
                let start = i

                if c == "0" && chars.index(after: i) < chars.endIndex {
                    let next = chars[chars.index(after: i)]
                    if next == "x" || next == "X" {
                        // Hex literal
                        i = chars.index(after: chars.index(after: i))
                        while i < chars.endIndex && chars[i].isHexDigit {
                            i = chars.index(after: i)
                        }
                        // Underscore separators
                        while i < chars.endIndex && (chars[i].isHexDigit || chars[i] == "_") {
                            i = chars.index(after: i)
                        }
                        // BigInt suffix
                        if i < chars.endIndex && chars[i] == "n" {
                            i = chars.index(after: i)
                        }
                        tokens.append(HighlightToken(range: start..<i, type: .number))
                        continue
                    } else if next == "b" || next == "B" {
                        // Binary literal
                        i = chars.index(after: chars.index(after: i))
                        while i < chars.endIndex && (chars[i] == "0" || chars[i] == "1" || chars[i] == "_") {
                            i = chars.index(after: i)
                        }
                        if i < chars.endIndex && chars[i] == "n" {
                            i = chars.index(after: i)
                        }
                        tokens.append(HighlightToken(range: start..<i, type: .number))
                        continue
                    } else if next == "o" || next == "O" {
                        // Octal literal
                        i = chars.index(after: chars.index(after: i))
                        while i < chars.endIndex && (chars[i] >= "0" && chars[i] <= "7" || chars[i] == "_") {
                            i = chars.index(after: i)
                        }
                        if i < chars.endIndex && chars[i] == "n" {
                            i = chars.index(after: i)
                        }
                        tokens.append(HighlightToken(range: start..<i, type: .number))
                        continue
                    }
                }

                // Decimal integer / float
                while i < chars.endIndex && (chars[i].isNumber || chars[i] == "_") {
                    i = chars.index(after: i)
                }
                // Decimal point
                if i < chars.endIndex && chars[i] == "." && (chars.index(after: i) >= chars.endIndex || chars[chars.index(after: i)] != ".") {
                    i = chars.index(after: i)
                    while i < chars.endIndex && (chars[i].isNumber || chars[i] == "_") {
                        i = chars.index(after: i)
                    }
                }
                // Exponent
                if i < chars.endIndex && (chars[i] == "e" || chars[i] == "E") {
                    i = chars.index(after: i)
                    if i < chars.endIndex && (chars[i] == "+" || chars[i] == "-") {
                        i = chars.index(after: i)
                    }
                    while i < chars.endIndex && (chars[i].isNumber || chars[i] == "_") {
                        i = chars.index(after: i)
                    }
                }
                // BigInt suffix
                if i < chars.endIndex && chars[i] == "n" {
                    i = chars.index(after: i)
                }

                tokens.append(HighlightToken(range: start..<i, type: .number))
                continue
            }

            // -----------------------------------------------------------
            // Identifiers / keywords / types / function calls
            // -----------------------------------------------------------
            if c.isLetter || c == "_" || c == "$" {
                let start = i
                i = chars.index(after: i)
                while i < chars.endIndex && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "$") {
                    i = chars.index(after: i)
                }
                let word = String(chars[start..<i])

                // Skip whitespace to check for function call
                var peek = i
                while peek < chars.endIndex && (chars[peek] == " " || chars[peek] == "\t") {
                    peek = chars.index(after: peek)
                }

                if keywords.contains(word) {
                    tokens.append(HighlightToken(range: start..<i, type: .keyword))
                } else if peek < chars.endIndex && chars[peek] == "(" {
                    tokens.append(HighlightToken(range: start..<i, type: .functionCall))
                } else if word.first?.isUppercase == true {
                    tokens.append(HighlightToken(range: start..<i, type: .type))
                } else {
                    tokens.append(HighlightToken(range: start..<i, type: .plain))
                }
                continue
            }

            // -----------------------------------------------------------
            // JSX: self-closing tags like <Component /> and closing tags </Component>
            // Angle brackets followed by an uppercase letter indicate a JSX type
            // -----------------------------------------------------------
            if c == "<" {
                let start = i
                var next = chars.index(after: i)

                // Check for closing tag  </Identifier>
                if next < chars.endIndex && chars[next] == "/" {
                    let slashIdx = next
                    next = chars.index(after: next)
                    if next < chars.endIndex && (chars[next].isLetter || chars[next] == "_" || chars[next] == "$") {
                        // Emit < and / as punctuation, then let the identifier be picked up on next iteration
                        i = chars.index(after: slashIdx)
                        tokens.append(HighlightToken(range: start..<i, type: .punctuation))
                        continue
                    }
                }

                // Fall through to operator handling below
                // (Regular < is an operator)
            }

            // -----------------------------------------------------------
            // Operators
            // -----------------------------------------------------------
            if operators.contains(c) {
                let start = i
                i = chars.index(after: i)
                // Consume runs of operator characters (e.g. ===, !==, =>, >>>, etc.)
                while i < chars.endIndex && operators.contains(chars[i]) {
                    i = chars.index(after: i)
                }
                tokens.append(HighlightToken(range: start..<i, type: .operator_))
                continue
            }

            // -----------------------------------------------------------
            // Arrow =>  is already handled above by operator grouping
            // Spread / rest ... is punctuation
            // -----------------------------------------------------------

            // -----------------------------------------------------------
            // Punctuation
            // -----------------------------------------------------------
            if punctuation.contains(c) {
                let start = i
                i = chars.index(after: i)
                // Handle spread/rest operator ...
                if c == "." && i < chars.endIndex && chars[i] == "." {
                    let second = i
                    let third = chars.index(after: second)
                    if third < chars.endIndex && chars[third] == "." {
                        i = chars.index(after: third)
                        tokens.append(HighlightToken(range: start..<i, type: .operator_))
                        continue
                    }
                }
                tokens.append(HighlightToken(range: start..<i, type: .punctuation))
                continue
            }

            // -----------------------------------------------------------
            // JSX closing >  (not part of operator since we handle < above)
            // Treat standalone > as punctuation when it isn't part of an operator run
            // -----------------------------------------------------------

            // -----------------------------------------------------------
            // Regex literals -- basic heuristic: /.../ not preceded by an identifier
            // (Skipped for simplicity -- very hard to get right without full parsing)
            // -----------------------------------------------------------

            // -----------------------------------------------------------
            // Hash # for private fields
            // -----------------------------------------------------------
            if c == "#" {
                let start = i
                i = chars.index(after: i)
                while i < chars.endIndex && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_") {
                    i = chars.index(after: i)
                }
                if chars.distance(from: start, to: i) > 1 {
                    tokens.append(HighlightToken(range: start..<i, type: .plain))
                } else {
                    tokens.append(HighlightToken(range: start..<i, type: .punctuation))
                }
                continue
            }

            // -----------------------------------------------------------
            // Whitespace and other characters -- skip
            // -----------------------------------------------------------
            i = chars.index(after: i)
        }

        return tokens
    }

    // MARK: - Template literal helper

    /// Parses a template literal starting at the opening backtick,
    /// advancing `index` past the closing backtick (or to the end of source).
    /// Emits string tokens for literal portions and recursively tokenizes
    /// interpolation expressions inside `${...}`.
    private static func tokenizeTemplateLiteral(
        source chars: String,
        index i: inout String.Index,
        tokens: inout [HighlightToken]
    ) {
        // `i` points at the opening backtick
        var segmentStart = i
        i = chars.index(after: i) // skip opening backtick

        while i < chars.endIndex {
            let c = chars[i]

            if c == "`" {
                // Closing backtick -- emit remaining string segment including backtick
                i = chars.index(after: i)
                tokens.append(HighlightToken(range: segmentStart..<i, type: .string))
                return
            }

            if c == "\\" && chars.index(after: i) < chars.endIndex {
                // Escaped character -- skip two
                i = chars.index(after: chars.index(after: i))
                continue
            }

            if c == "$" && chars.index(after: i) < chars.endIndex && chars[chars.index(after: i)] == "{" {
                // Emit the string segment up to (and including) the characters before ${
                if segmentStart < i {
                    tokens.append(HighlightToken(range: segmentStart..<i, type: .string))
                }

                // Emit ${ as punctuation
                let interpStart = i
                i = chars.index(after: chars.index(after: i)) // skip ${
                tokens.append(HighlightToken(range: interpStart..<i, type: .punctuation))

                // Find the matching closing brace, tracking nesting depth
                var depth = 1
                let bodyStart = i
                while i < chars.endIndex && depth > 0 {
                    if chars[i] == "{" {
                        depth += 1
                    } else if chars[i] == "}" {
                        depth -= 1
                        if depth == 0 { break }
                    }
                    i = chars.index(after: i)
                }

                // Recursively tokenize the inner expression
                if bodyStart < i {
                    let innerSource = String(chars[bodyStart..<i])
                    let innerTokens = tokenize(innerSource)
                    for inner in innerTokens {
                        let offsetStart = chars.index(bodyStart, offsetBy: chars.distance(from: innerSource.startIndex, to: inner.range.lowerBound))
                        let offsetEnd = chars.index(bodyStart, offsetBy: chars.distance(from: innerSource.startIndex, to: inner.range.upperBound))
                        tokens.append(HighlightToken(range: offsetStart..<offsetEnd, type: inner.type))
                    }
                }

                // Emit closing } as punctuation
                if i < chars.endIndex {
                    let closeBrace = i
                    i = chars.index(after: i) // skip }
                    tokens.append(HighlightToken(range: closeBrace..<i, type: .punctuation))
                }

                // Start a new string segment after the interpolation
                segmentStart = i
                continue
            }

            i = chars.index(after: i)
        }

        // Unterminated template literal -- emit whatever we have
        if segmentStart < i {
            tokens.append(HighlightToken(range: segmentStart..<i, type: .string))
        }
    }
}
