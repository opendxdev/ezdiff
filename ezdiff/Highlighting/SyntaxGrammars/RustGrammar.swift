import Foundation

struct RustGrammar: SyntaxGrammar {
    static let languageID = "rust"

    private static let keywords: Set<String> = [
        "as", "async", "await", "break", "const", "continue", "crate", "dyn",
        "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in",
        "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return",
        "self", "Self", "static", "struct", "super", "trait", "true", "type",
        "unsafe", "use", "where", "while", "yield", "macro_rules"
    ]

    private static let operatorChars: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "!", "<", ">", "&", "|", "^", "~", "?", ".", ":"
    ]

    private static let punctuationChars: Set<Character> = [
        "(", ")", "{", "}", "[", "]", ",", ";", "#"
    ]

    static func tokenize(_ source: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        let chars = Array(source)
        let count = chars.count
        var i = 0

        // Map character array indices to String.Index
        let stringIndices = Array(source.indices) + [source.endIndex]

        while i < count {
            let ch = chars[i]

            // --- Line comments ---
            if ch == "/" && i + 1 < count && chars[i + 1] == "/" {
                let start = i
                i += 2
                while i < count && chars[i] != "\n" {
                    i += 1
                }
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .comment
                ))
                continue
            }

            // --- Block comments (with nesting) ---
            if ch == "/" && i + 1 < count && chars[i + 1] == "*" {
                let start = i
                i += 2
                var depth = 1
                while i < count && depth > 0 {
                    if chars[i] == "/" && i + 1 < count && chars[i + 1] == "*" {
                        depth += 1
                        i += 2
                    } else if chars[i] == "*" && i + 1 < count && chars[i + 1] == "/" {
                        depth -= 1
                        i += 2
                    } else {
                        i += 1
                    }
                }
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .comment
                ))
                continue
            }

            // --- Raw strings: r"..." or r#"..."# or r##"..."## etc. ---
            if ch == "r" && i + 1 < count && (chars[i + 1] == "\"" || chars[i + 1] == "#") {
                if let end = tryRawString(chars, from: i, count: count) {
                    tokens.append(HighlightToken(
                        range: stringIndices[i]..<stringIndices[end],
                        type: .string
                    ))
                    i = end
                    continue
                }
            }

            // --- Byte strings: b"...", b'...', br"...", br#"..."# ---
            if ch == "b" && i + 1 < count {
                let next = chars[i + 1]
                if next == "\"" {
                    let start = i
                    i += 2
                    i = skipStringBody(chars, from: i, count: count, delimiter: "\"")
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .string
                    ))
                    continue
                }
                if next == "'" {
                    let start = i
                    i += 2
                    i = skipStringBody(chars, from: i, count: count, delimiter: "'")
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .string
                    ))
                    continue
                }
                if next == "r" && i + 2 < count && (chars[i + 2] == "\"" || chars[i + 2] == "#") {
                    if let end = tryRawString(chars, from: i + 1, count: count) {
                        tokens.append(HighlightToken(
                            range: stringIndices[i]..<stringIndices[end],
                            type: .string
                        ))
                        i = end
                        continue
                    }
                }
            }

            // --- Double-quoted strings ---
            if ch == "\"" {
                let start = i
                i += 1
                i = skipStringBody(chars, from: i, count: count, delimiter: "\"")
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .string
                ))
                continue
            }

            // --- Character literals and lifetime annotations ---
            if ch == "'" {
                // Try lifetime annotation: 'identifier
                if i + 1 < count && isIdentStart(chars[i + 1]) {
                    let start = i
                    i += 1
                    while i < count && isIdentContinue(chars[i]) {
                        i += 1
                    }
                    // Check if this looks like a char literal: 'x'
                    if i < count && chars[i] == "'" {
                        // It's a character literal like 'a' or '\n'
                        i += 1
                        tokens.append(HighlightToken(
                            range: stringIndices[start]..<stringIndices[i],
                            type: .string
                        ))
                    } else {
                        // It's a lifetime annotation like 'a, 'static
                        tokens.append(HighlightToken(
                            range: stringIndices[start]..<stringIndices[i],
                            type: .type
                        ))
                    }
                    continue
                }
                // Character literal starting with escape: '\n', '\\'
                if i + 1 < count && chars[i + 1] == "\\" {
                    let start = i
                    i += 2
                    // Skip the escape sequence
                    if i < count {
                        if chars[i] == "x" {
                            // \xNN
                            i += 1
                            while i < count && isHexDigit(chars[i]) { i += 1 }
                        } else if chars[i] == "u" {
                            // \u{NNNN}
                            i += 1
                            if i < count && chars[i] == "{" {
                                i += 1
                                while i < count && chars[i] != "}" { i += 1 }
                                if i < count { i += 1 }
                            }
                        } else {
                            i += 1
                        }
                    }
                    if i < count && chars[i] == "'" {
                        i += 1
                    }
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .string
                    ))
                    continue
                }
                // Single char literal: 'x'
                if i + 2 < count && chars[i + 2] == "'" {
                    let start = i
                    i += 3
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .string
                    ))
                    continue
                }
                // Standalone apostrophe — treat as operator
                tokens.append(HighlightToken(
                    range: stringIndices[i]..<stringIndices[i + 1],
                    type: .operator_
                ))
                i += 1
                continue
            }

            // --- Numbers ---
            if ch.isNumber || (ch == "." && i + 1 < count && chars[i + 1].isNumber) {
                let start = i
                if ch == "0" && i + 1 < count {
                    let next = chars[i + 1]
                    if next == "x" || next == "X" {
                        // Hex
                        i += 2
                        while i < count && (isHexDigit(chars[i]) || chars[i] == "_") { i += 1 }
                        i = skipNumericSuffix(chars, from: i, count: count)
                        tokens.append(HighlightToken(
                            range: stringIndices[start]..<stringIndices[i],
                            type: .number
                        ))
                        continue
                    }
                    if next == "b" || next == "B" {
                        // Binary
                        i += 2
                        while i < count && (chars[i] == "0" || chars[i] == "1" || chars[i] == "_") { i += 1 }
                        i = skipNumericSuffix(chars, from: i, count: count)
                        tokens.append(HighlightToken(
                            range: stringIndices[start]..<stringIndices[i],
                            type: .number
                        ))
                        continue
                    }
                    if next == "o" || next == "O" {
                        // Octal
                        i += 2
                        while i < count && ((chars[i] >= "0" && chars[i] <= "7") || chars[i] == "_") { i += 1 }
                        i = skipNumericSuffix(chars, from: i, count: count)
                        tokens.append(HighlightToken(
                            range: stringIndices[start]..<stringIndices[i],
                            type: .number
                        ))
                        continue
                    }
                }
                // Decimal integer or float
                while i < count && (chars[i].isNumber || chars[i] == "_") { i += 1 }
                if i < count && chars[i] == "." && i + 1 < count && chars[i + 1] != "." {
                    // Check that what follows the dot is a digit or underscore (not an identifier start, which would be a method call)
                    if i + 1 < count && (chars[i + 1].isNumber || chars[i + 1] == "_") {
                        i += 1
                        while i < count && (chars[i].isNumber || chars[i] == "_") { i += 1 }
                    }
                }
                // Exponent
                if i < count && (chars[i] == "e" || chars[i] == "E") {
                    i += 1
                    if i < count && (chars[i] == "+" || chars[i] == "-") { i += 1 }
                    while i < count && (chars[i].isNumber || chars[i] == "_") { i += 1 }
                }
                i = skipNumericSuffix(chars, from: i, count: count)
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .number
                ))
                continue
            }

            // --- Identifiers, keywords, macros, types, function calls ---
            if isIdentStart(ch) {
                let start = i
                i += 1
                while i < count && isIdentContinue(chars[i]) {
                    i += 1
                }
                let word = String(chars[start..<i])

                // Macro invocation: identifier!
                if i < count && chars[i] == "!" {
                    // macro_rules! or any_macro!
                    let macroEnd = i + 1
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[macroEnd],
                        type: .functionCall
                    ))
                    i = macroEnd
                    continue
                }

                // Check for keyword
                if keywords.contains(word) {
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .keyword
                    ))
                    continue
                }

                // Function call: identifier followed by optional whitespace and (
                let savedI = i
                var peekI = i
                while peekI < count && chars[peekI] == " " { peekI += 1 }
                if peekI < count && chars[peekI] == "(" {
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[savedI],
                        type: .functionCall
                    ))
                    continue
                }

                // Type: starts with uppercase letter
                if let first = word.first, first.isUppercase {
                    tokens.append(HighlightToken(
                        range: stringIndices[start]..<stringIndices[i],
                        type: .type
                    ))
                    continue
                }

                // Plain identifier
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .plain
                ))
                continue
            }

            // --- Operators ---
            if operatorChars.contains(ch) {
                let start = i
                i += 1
                // Consume consecutive operator characters
                while i < count && operatorChars.contains(chars[i]) {
                    i += 1
                }
                tokens.append(HighlightToken(
                    range: stringIndices[start]..<stringIndices[i],
                    type: .operator_
                ))
                continue
            }

            // --- Punctuation ---
            if punctuationChars.contains(ch) {
                tokens.append(HighlightToken(
                    range: stringIndices[i]..<stringIndices[i + 1],
                    type: .punctuation
                ))
                i += 1
                continue
            }

            // --- Whitespace and other characters ---
            i += 1
        }

        return tokens
    }

    // MARK: - Helpers

    private static func isIdentStart(_ ch: Character) -> Bool {
        ch.isLetter || ch == "_"
    }

    private static func isIdentContinue(_ ch: Character) -> Bool {
        ch.isLetter || ch.isNumber || ch == "_"
    }

    private static func isHexDigit(_ ch: Character) -> Bool {
        (ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F")
    }

    /// Skip past a string body terminated by the given delimiter, handling backslash escapes.
    /// `from` should point to the character after the opening delimiter.
    /// Returns the index after the closing delimiter (or end of input).
    private static func skipStringBody(_ chars: [Character], from start: Int, count: Int, delimiter: Character) -> Int {
        var i = start
        while i < count {
            if chars[i] == "\\" {
                i += 2
            } else if chars[i] == delimiter {
                i += 1
                return i
            } else {
                i += 1
            }
        }
        return i
    }

    /// Try to parse a raw string starting at `from` (which points to the 'r').
    /// Returns the index past the closing delimiter, or nil if this is not a raw string.
    private static func tryRawString(_ chars: [Character], from start: Int, count: Int) -> Int? {
        var i = start
        guard i < count && chars[i] == "r" else { return nil }
        i += 1

        // Count leading hashes
        var hashes = 0
        while i < count && chars[i] == "#" {
            hashes += 1
            i += 1
        }
        guard i < count && chars[i] == "\"" else { return nil }
        i += 1

        // Find closing: "followed by same number of #
        while i < count {
            if chars[i] == "\"" {
                i += 1
                var matched = 0
                while matched < hashes && i < count && chars[i] == "#" {
                    matched += 1
                    i += 1
                }
                if matched == hashes {
                    return i
                }
            } else {
                i += 1
            }
        }
        return i
    }

    /// Skip a numeric type suffix like u8, i32, f64, usize, isize, etc.
    private static func skipNumericSuffix(_ chars: [Character], from start: Int, count: Int) -> Int {
        var i = start
        guard i < count else { return i }

        let ch = chars[i]
        if ch == "u" || ch == "i" || ch == "f" {
            let saved = i
            i += 1
            // Check for known suffixes: u8, u16, u32, u64, u128, usize, i8, i16, i32, i64, i128, isize, f32, f64
            var suffixLen = 0
            while i < count && (chars[i].isNumber || isIdentContinue(chars[i])) {
                suffixLen += 1
                i += 1
            }
            if suffixLen == 0 {
                // Just a lone u/i/f — not a suffix, revert
                return saved
            }
            let suffix = String(chars[saved..<i])
            let validSuffixes: Set<String> = [
                "u8", "u16", "u32", "u64", "u128", "usize",
                "i8", "i16", "i32", "i64", "i128", "isize",
                "f32", "f64"
            ]
            if validSuffixes.contains(suffix) {
                return i
            }
            // Not a known suffix, revert
            return saved
        }
        return i
    }
}
