import Foundation

struct YAMLGrammar: SyntaxGrammar {

    static let languageID = "yaml"

    // MARK: - Boolean / null literals

    private static let booleanLiterals: Set<String> = [
        "true", "false", "yes", "no", "on", "off",
        "True", "False", "Yes", "No", "On", "Off",
        "TRUE", "FALSE", "YES", "NO", "ON", "OFF",
    ]

    private static let nullLiterals: Set<String> = [
        "null", "Null", "NULL", "~",
    ]

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex
        var lineStart = true

        while index < source.endIndex {
            let c = source[index]

            // Track line starts
            if c == "\n" {
                index = source.index(after: index)
                lineStart = true
                continue
            }

            // --- Comment: # (when preceded by whitespace or at line start) ---
            if c == "#" {
                let start = index
                while index < source.endIndex && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                lineStart = false
                continue
            }

            // --- Document markers: --- and ... ---
            if lineStart && (c == "-" || c == ".") {
                let start = index
                let remaining = source[index...]
                if remaining.hasPrefix("---") || remaining.hasPrefix("...") {
                    let marker = source.index(index, offsetBy: 3, limitedBy: source.endIndex) ?? source.endIndex
                    // Ensure it's the whole line content (followed by whitespace/newline/eof)
                    if marker >= source.endIndex || source[marker].isWhitespace || source[marker] == "\n" {
                        index = marker
                        tokens.append(HighlightToken(range: start..<index, type: .keyword))
                        lineStart = false
                        continue
                    }
                }
            }

            // --- Anchor: &name ---
            if c == "&" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex && !source[index].isWhitespace && source[index] != "\n" && source[index] != ":" && source[index] != "," && source[index] != "]" && source[index] != "}" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .type))
                lineStart = false
                continue
            }

            // --- Alias: *name ---
            if c == "*" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex && !source[index].isWhitespace && source[index] != "\n" && source[index] != ":" && source[index] != "," && source[index] != "]" && source[index] != "}" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .type))
                lineStart = false
                continue
            }

            // --- Tag: !!type ---
            if c == "!" {
                let start = index
                index = source.index(after: index)
                if index < source.endIndex && source[index] == "!" {
                    index = source.index(after: index)
                }
                while index < source.endIndex && !source[index].isWhitespace && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .type))
                lineStart = false
                continue
            }

            // --- Single-quoted string ---
            if c == "'" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex {
                    if source[index] == "'" {
                        let next = source.index(after: index)
                        if next < source.endIndex && source[next] == "'" {
                            // Escaped single quote ''
                            index = source.index(after: next)
                        } else {
                            index = source.index(after: index) // skip closing '
                            break
                        }
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                lineStart = false
                continue
            }

            // --- Double-quoted string ---
            if c == "\"" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex {
                    if source[index] == "\\" {
                        let afterBackslash = source.index(after: index)
                        if afterBackslash < source.endIndex {
                            index = source.index(after: afterBackslash)
                        } else {
                            index = source.index(after: index)
                        }
                    } else if source[index] == "\"" {
                        index = source.index(after: index)
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                lineStart = false
                continue
            }

            // --- Whitespace (spaces and tabs) ---
            if c == " " || c == "\t" {
                index = source.index(after: index)
                continue
            }

            // --- Punctuation: { } [ ] , : - (list marker) ---
            if c == "{" || c == "}" || c == "[" || c == "]" || c == "," {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                lineStart = false
                continue
            }

            // --- Unquoted text: could be key, boolean, null, number, or plain value ---
            if c.isLetter || c == "_" || c == "~" || c == "-" || c == "." || c.isNumber {
                let start = index

                // Consume the word/value
                while index < source.endIndex && source[index] != "\n" && source[index] != "#" && source[index] != ":" && source[index] != "," && source[index] != "{" && source[index] != "}" && source[index] != "[" && source[index] != "]" {
                    index = source.index(after: index)
                }

                // Trim trailing whitespace from the captured range
                var end = index
                while end > start {
                    let prev = source.index(before: end)
                    if source[prev] == " " || source[prev] == "\t" {
                        end = prev
                    } else {
                        break
                    }
                }

                let word = String(source[start..<end])

                // Check if followed by : (this is a key)
                var lookahead = index
                while lookahead < source.endIndex && (source[lookahead] == " " || source[lookahead] == "\t") {
                    lookahead = source.index(after: lookahead)
                }

                if lookahead < source.endIndex && source[lookahead] == ":" {
                    tokens.append(HighlightToken(range: start..<end, type: .keyword))
                    lineStart = false
                    continue
                }

                // Check for boolean
                if booleanLiterals.contains(word) {
                    tokens.append(HighlightToken(range: start..<end, type: .keyword))
                    lineStart = false
                    continue
                }

                // Check for null
                if nullLiterals.contains(word) {
                    tokens.append(HighlightToken(range: start..<end, type: .keyword))
                    lineStart = false
                    continue
                }

                // Check for number
                if isNumber(word) {
                    tokens.append(HighlightToken(range: start..<end, type: .number))
                    lineStart = false
                    continue
                }

                tokens.append(HighlightToken(range: start..<end, type: .plain))
                lineStart = false
                continue
            }

            // --- Colon as punctuation ---
            if c == ":" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                lineStart = false
                continue
            }

            // --- Anything else ---
            index = source.index(after: index)
            lineStart = false
        }

        return tokens
    }

    // MARK: - Helpers

    private static func isNumber(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        var idx = s.startIndex
        if s[idx] == "-" || s[idx] == "+" {
            idx = s.index(after: idx)
        }
        guard idx < s.endIndex && s[idx].isNumber else { return false }
        var hasDot = false
        while idx < s.endIndex {
            if s[idx].isNumber {
                idx = s.index(after: idx)
            } else if s[idx] == "." && !hasDot {
                hasDot = true
                idx = s.index(after: idx)
            } else if s[idx] == "e" || s[idx] == "E" {
                idx = s.index(after: idx)
                if idx < s.endIndex && (s[idx] == "+" || s[idx] == "-") {
                    idx = s.index(after: idx)
                }
                guard idx < s.endIndex && s[idx].isNumber else { return false }
                while idx < s.endIndex && s[idx].isNumber {
                    idx = s.index(after: idx)
                }
                return idx == s.endIndex
            } else {
                return false
            }
        }
        return true
    }
}
