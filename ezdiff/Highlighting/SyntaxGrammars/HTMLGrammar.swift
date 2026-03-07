import Foundation

struct HTMLGrammar: SyntaxGrammar {

    static let languageID = "html"

    // MARK: - Tokenize

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = source.startIndex

        while index < source.endIndex {
            let c = source[index]

            // --- HTML Comment: <!-- --> ---
            if c == "<" {
                let remaining = source[index...]
                if remaining.hasPrefix("<!--") {
                    let start = index
                    index = source.index(index, offsetBy: 4, limitedBy: source.endIndex) ?? source.endIndex
                    // Find -->
                    while index < source.endIndex {
                        if source[index] == "-" {
                            let next1 = source.index(after: index)
                            if next1 < source.endIndex && source[next1] == "-" {
                                let next2 = source.index(after: next1)
                                if next2 < source.endIndex && source[next2] == ">" {
                                    index = source.index(after: next2)
                                    break
                                }
                            }
                        }
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .comment))
                    continue
                }

                // --- DOCTYPE ---
                if remaining.hasPrefix("<!DOCTYPE") || remaining.hasPrefix("<!doctype") {
                    let start = index
                    while index < source.endIndex && source[index] != ">" {
                        index = source.index(after: index)
                    }
                    if index < source.endIndex {
                        index = source.index(after: index) // skip >
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                    continue
                }

                // --- Tag: opening < ---
                let tagStart = index
                index = source.index(after: index) // skip <
                tokens.append(HighlightToken(range: tagStart..<index, type: .punctuation))

                // Check for closing tag /
                if index < source.endIndex && source[index] == "/" {
                    let slashStart = index
                    index = source.index(after: index)
                    tokens.append(HighlightToken(range: slashStart..<index, type: .punctuation))
                }

                // Skip whitespace
                while index < source.endIndex && (source[index] == " " || source[index] == "\t" || source[index] == "\n" || source[index] == "\r") {
                    index = source.index(after: index)
                }

                // Tag name
                if index < source.endIndex && (source[index].isLetter || source[index] == "_") {
                    let nameStart = index
                    while index < source.endIndex && (source[index].isLetter || source[index].isNumber || source[index] == "-" || source[index] == "_" || source[index] == ":") {
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: nameStart..<index, type: .keyword))
                }

                // Attributes inside the tag
                parseAttributes(source: source, index: &index, tokens: &tokens)

                continue
            }

            // --- Entity reference: &amp; etc. ---
            if c == "&" {
                let start = index
                index = source.index(after: index)
                if index < source.endIndex && (source[index].isLetter || source[index] == "#") {
                    while index < source.endIndex && source[index] != ";" && source[index] != " " && source[index] != "\n" && source[index] != "<" {
                        index = source.index(after: index)
                    }
                    if index < source.endIndex && source[index] == ";" {
                        index = source.index(after: index)
                    }
                    tokens.append(HighlightToken(range: start..<index, type: .keyword))
                } else {
                    tokens.append(HighlightToken(range: start..<index, type: .plain))
                }
                continue
            }

            // --- Plain text ---
            index = source.index(after: index)
        }

        return tokens
    }

    // MARK: - Attribute Parsing

    private static func parseAttributes(source: String, index: inout String.Index, tokens: inout [HighlightToken]) {
        while index < source.endIndex {
            let c = source[index]

            // End of tag
            if c == ">" {
                let start = index
                index = source.index(after: index)
                tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                return
            }

            // Self-closing />
            if c == "/" {
                let next = source.index(after: index)
                if next < source.endIndex && source[next] == ">" {
                    let start = index
                    index = source.index(after: next)
                    tokens.append(HighlightToken(range: start..<index, type: .punctuation))
                    return
                }
            }

            // Whitespace
            if c.isWhitespace {
                index = source.index(after: index)
                continue
            }

            // Attribute name
            if c.isLetter || c == "_" || c == ":" || c == "@" || c == "v" {
                let attrStart = index
                while index < source.endIndex && !source[index].isWhitespace && source[index] != "=" && source[index] != ">" && source[index] != "/" {
                    index = source.index(after: index)
                }
                tokens.append(HighlightToken(range: attrStart..<index, type: .type))

                // Skip whitespace
                while index < source.endIndex && source[index].isWhitespace {
                    index = source.index(after: index)
                }

                // = sign
                if index < source.endIndex && source[index] == "=" {
                    let eqStart = index
                    index = source.index(after: index)
                    tokens.append(HighlightToken(range: eqStart..<index, type: .punctuation))

                    // Skip whitespace
                    while index < source.endIndex && source[index].isWhitespace {
                        index = source.index(after: index)
                    }

                    // Attribute value
                    if index < source.endIndex {
                        if source[index] == "\"" {
                            let valStart = index
                            index = source.index(after: index)
                            while index < source.endIndex && source[index] != "\"" {
                                index = source.index(after: index)
                            }
                            if index < source.endIndex {
                                index = source.index(after: index) // skip closing "
                            }
                            tokens.append(HighlightToken(range: valStart..<index, type: .string))
                        } else if source[index] == "'" {
                            let valStart = index
                            index = source.index(after: index)
                            while index < source.endIndex && source[index] != "'" {
                                index = source.index(after: index)
                            }
                            if index < source.endIndex {
                                index = source.index(after: index)
                            }
                            tokens.append(HighlightToken(range: valStart..<index, type: .string))
                        } else {
                            // Unquoted value
                            let valStart = index
                            while index < source.endIndex && !source[index].isWhitespace && source[index] != ">" && source[index] != "/" {
                                index = source.index(after: index)
                            }
                            tokens.append(HighlightToken(range: valStart..<index, type: .string))
                        }
                    }
                }
                continue
            }

            // Unknown character inside tag
            index = source.index(after: index)
        }
    }
}
