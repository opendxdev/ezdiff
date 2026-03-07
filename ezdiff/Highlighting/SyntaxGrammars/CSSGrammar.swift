import Foundation

struct CSSGrammar: SyntaxGrammar {

    static let languageID = "css"

    // MARK: - State

    private enum State {
        case topLevel
        case insideBlock
    }

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex
        var state: State = .topLevel

        while index < source.endIndex {
            let c = source[index]

            // --- Comment: /* */ ---
            if c == "/" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "*" {
                    let start = index
                    index = source.index(after: next) // skip /*
                    while index < source.endIndex {
                        if source[index] == "*" {
                            let afterStar = source.index(after: index)
                            if afterStar < source.endIndex && source[afterStar] == "/" {
                                index = source.index(after: afterStar)
                                break
                            }
                        }
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .comment))
                    continue
                }
            }

            // --- Whitespace ---
            if c.isWhitespace {
                index = source.index(after: index)
                continue
            }

            // --- String: single or double-quoted ---
            if c == "\"" || c == "'" {
                let quote = c
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
                    } else if source[index] == quote {
                        index = source.index(after: index)
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- At-rule: @media, @import, etc. ---
            if c == "@" {
                let start = index
                index = source.index(after: index)
                while index < source.endIndex && (source[index].isLetter || source[index] == "-") {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .keyword))
                continue
            }

            // --- Color hex: #hex ---
            if c == "#" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next].isHexDigit {
                    let start = index
                    index = source.index(after: index)
                    while index < source.endIndex && source[index].isHexDigit {
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .number))
                    continue
                }
            }

            // --- Punctuation: { } ; , ---
            if c == "{" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                state = .insideBlock
                continue
            }

            if c == "}" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                state = .topLevel
                continue
            }

            if c == ";" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            if c == "," {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            if c == ":" || c == "(" || c == ")" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                continue
            }

            // --- Number with optional unit ---
            if c.isNumber || (c == "." && {
                let next = source.index(after: index)
                return next < source.endIndex && source[next].isNumber
            }()) {
                let start = index
                // Consume digits and decimal point
                while index < source.endIndex && (source[index].isNumber || source[index] == ".") {
                    index = source.index(after: index)
                }
                // Consume unit suffix (px, em, rem, %, vh, vw, etc.)
                if index < source.endIndex && (source[index].isLetter || source[index] == "%") {
                    while index < source.endIndex && (source[index].isLetter || source[index] == "%") {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .number))
                continue
            }

            // --- Identifiers and selectors ---
            if c.isLetter || c == "_" || c == "-" || c == "." || c == "#" || c == "*" || c == ">" || c == "+" || c == "~" || c == "[" || c == "]" || c == "!" {
                if state == .insideBlock {
                    // Inside a block: could be property name or value
                    let start = index

                    // Read until : or ; or } or {
                    while index < source.endIndex && source[index] != ":" && source[index] != ";" && source[index] != "}" && source[index] != "{" && source[index] != "\n" {
                        // Skip strings inside values
                        if source[index] == "\"" || source[index] == "'" {
                            break
                        }
                        // Skip comments
                        if source[index] == "/" {
                            let next = source.index(after: index)
                            if next < source.endIndex && source[next] == "*" {
                                break
                            }
                        }
                        index = source.index(after: index)
                    }

                    // Trim trailing whitespace
                    var end = index
                    while end > start {
                        let prev = source.index(before: end)
                        if source[prev] == " " || source[prev] == "\t" {
                            end = prev
                        } else {
                            break
                        }
                    }

                    if end > start {
                        // Check if followed by : (property name)
                        var lookahead = index
                        while lookahead < source.endIndex && (source[lookahead] == " " || source[lookahead] == "\t") {
                            lookahead = source.index(after: lookahead)
                        }
                        if lookahead < source.endIndex && source[lookahead] == ":" {
                            tokens.append(HighlightToken(range: start..<end, type: .keyword))
                        } else {
                            tokens.append(HighlightToken(range: start..<end, type: .plain))
                        }
                    }
                    continue
                } else {
                    // Top level: selector
                    let start = index
                    while index < source.endIndex && source[index] != "{" && source[index] != ";" {
                        // Skip comments
                        if source[index] == "/" {
                            let next = source.index(after: index)
                            if next < source.endIndex && source[next] == "*" {
                                break
                            }
                        }
                        // Skip strings
                        if source[index] == "\"" || source[index] == "'" {
                            break
                        }
                        index = source.index(after: index)
                    }

                    // Trim trailing whitespace
                    var end = index
                    while end > start {
                        let prev = source.index(before: end)
                        if source[prev] == " " || source[prev] == "\t" || source[prev] == "\n" || source[prev] == "\r" {
                            end = prev
                        } else {
                            break
                        }
                    }

                    if end > start {
                        tokens.append(HighlightToken(range: start..<end, type: .type))
                    }
                    continue
                }
            }

            // --- Anything else ---
            index = source.index(after: index)
        }

        return tokens
    }
}
