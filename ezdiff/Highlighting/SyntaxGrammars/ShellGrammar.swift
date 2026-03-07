import Foundation

struct ShellGrammar: SyntaxGrammar {

    static let languageID = "shell"

    // MARK: - Keywords

    private static let keywords: Set<String> = [
        "echo", "cd", "ls", "grep", "awk", "sed", "export", "source",
        "alias", "unalias", "if", "then", "else", "elif", "fi",
        "case", "esac", "for", "while", "do", "done", "function",
        "return", "exit", "local", "readonly", "declare", "typeset",
        "eval", "exec", "set", "unset", "shift", "trap", "wait", "test",
    ]

    private static let operatorChars: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "!", "<", ">", "&", "|", "^", "~",
    ]

    private static let punctuationChars: Set<Character> = [
        "(", ")", "{", "}", "[", "]", ",", ";",
    ]

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex

        while index < source.endIndex {
            let c = source[index]

            // --- Comment: # to end of line ---
            if c == "#" {
                // Make sure it's not inside ${...} (variable expansion)
                let start = index
                while index < source.endIndex && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                continue
            }

            // --- Single-quoted string (no interpolation) ---
            if c == "'" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex && source[index] != "'" {
                    index = source.index(after: index)
                }
                if index < source.endIndex {
                    index = source.index(after: index) // skip closing '
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Double-quoted string (with escape sequences) ---
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
                continue
            }

            // --- Variable references: $VAR, ${VAR}, $1, $@, $?, $$ ---
            if c == "$" {
                let start = index
                index = source.index(after: index)
                if index < source.endIndex {
                    let next = source[index]
                    if next == "{" {
                        // ${VAR}
                        index = source.index(after: index)
                        while index < source.endIndex && source[index] != "}" {
                            index = source.index(after: index)
                        }
                        if index < source.endIndex {
                            index = source.index(after: index) // skip }
                        }
                        tokens.append(HighlightToken(range: start..<index, type: .type))
                        continue
                    } else if next == "(" {
                        // $(command) — treat $ as operator
                        tokens.append(HighlightToken(range: start..<index, type: .operator_))
                        continue
                    } else if next.isLetter || next == "_" {
                        // $VAR
                        while index < source.endIndex && (source[index].isLetter || source[index].isNumber || source[index] == "_") {
                            index = source.index(after: index)
                        }
                        tokens.append(HighlightToken(range: start..<index, type: .type))
                        continue
                    } else if next.isNumber || next == "@" || next == "?" || next == "$" || next == "#" || next == "!" || next == "*" || next == "-" {
                        // $1, $@, $?, $$, $#, $!, $*, $-
                        index = source.index(after: index)
                        tokens.append(HighlightToken(range: start..<index, type: .type))
                        continue
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .operator_))
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

            // --- Identifiers and keywords ---
            if c.isLetter || c == "_" {
                let start = index
                while index < source.endIndex && (source[index].isLetter || source[index].isNumber || source[index] == "_" || source[index] == "-") {
                    index = source.index(after: index)
                }
                let word = String(source[start..<index])

                if keywords.contains(word) {
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                } else {
                    // Check if followed by ( for function call
                    var lookahead = index
                    while lookahead < source.endIndex && (source[lookahead] == " " || source[lookahead] == "\t") {
                        lookahead = source.index(after: lookahead)
                    }
                    if lookahead < source.endIndex && source[lookahead] == "(" {
                        tokens.append(HighlightToken(range: start..<index, type: .functionCall))
                    } else {
                        tokens.append(HighlightToken(range: start..<index, type: .plain))
                    }
                }
                continue
            }

            // --- Operators ---
            if operatorChars.contains(c) {
                let start = index
                while index < source.endIndex && operatorChars.contains(source[index]) {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .operator_))
                continue
            }

            // --- Punctuation ---
            if punctuationChars.contains(c) {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Whitespace and other ---
            index = source.index(after: index)
        }

        return tokens
    }
}
