import Foundation

struct GenericGrammar: SyntaxGrammar {

    static let languageID = "generic"

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex

        while index < source.endIndex {
            let c = source[index]

            // --- Single-line comment: // ---
            if c == "/" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == "/" {
                    let start = index
                    while index < source.endIndex && source[index] != "\n" {
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .comment))
                    continue
                }

                // --- Multi-line comment: /* */ ---
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

            // --- Hash comment: # ---
            if c == "#" {
                let start = index
                while index < source.endIndex && source[index] != "\n" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .comment))
                continue
            }

            // --- Double-quoted string ---
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
                    } else if source[index] == "\n" {
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Single-quoted string ---
            if c == "'" {
                let start = index
                index = source.index(after: index) // skip opening '
                while index < source.endIndex {
                    if source[index] == "\\" {
                        let afterBackslash = source.index(after: index)
                        if afterBackslash < source.endIndex {
                            index = source.index(after: afterBackslash)
                        } else {
                            index = source.index(after: index)
                        }
                    } else if source[index] == "'" {
                        index = source.index(after: index) // skip closing '
                        break
                    } else if source[index] == "\n" {
                        break
                    } else {
                        index = source.index(after: index)
                    }
                }
                tokens.append(HighlightToken(range: start..<index, type: .string))
                continue
            }

            // --- Numbers ---
            if c.isNumber || (c == "." && {
                let next = source.index(after: index)
                return next < source.endIndex && source[next].isNumber
            }()) {
                let start = index

                // Check for hex prefix
                if c == "0" {
                    let next = source.index(after: index)
                    if next < source.endIndex && (source[next] == "x" || source[next] == "X") {
                        index = source.index(after: next)
                        while index < source.endIndex && (source[index].isHexDigit || source[index] == "_") {
                            index = source.index(after: index)
                        }
                        tokens.append(HighlightToken(range: start..<index, type: .number))
                        continue
                    }
                }

                // Decimal
                while index < source.endIndex && (source[index].isNumber || source[index] == "_") {
                    index = source.index(after: index)
                }
                // Fractional part
                if index < source.endIndex && source[index] == "." {
                    let afterDot = source.index(after: index)
                    if afterDot < source.endIndex && source[afterDot].isNumber {
                        index = source.index(after: index)
                        while index < source.endIndex && (source[index].isNumber || source[index] == "_") {
                            index = source.index(after: index)
                        }
                    }
                }
                // Exponent
                if index < source.endIndex && (source[index] == "e" || source[index] == "E") {
                    let afterE = source.index(after: index)
                    if afterE < source.endIndex {
                        var expIdx = afterE
                        if source[expIdx] == "+" || source[expIdx] == "-" {
                            expIdx = source.index(after: expIdx)
                        }
                        if expIdx < source.endIndex && source[expIdx].isNumber {
                            index = expIdx
                            while index < source.endIndex && (source[index].isNumber || source[index] == "_") {
                                index = source.index(after: index)
                            }
                        }
                    }
                }

                tokens.append(HighlightToken(range: start..<index, type: .number))
                continue
            }

            // --- Identifiers (plain) ---
            if c.isLetter || c == "_" {
                let start = index
                while index < source.endIndex && (source[index].isLetter || source[index].isNumber || source[index] == "_") {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: start..<index, type: .plain))
                continue
            }

            // --- Whitespace and anything else ---
            index = source.index(after: index)
        }

        return tokens
    }
}
