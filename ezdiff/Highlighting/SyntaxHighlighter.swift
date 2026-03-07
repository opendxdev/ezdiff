import AppKit

struct SyntaxTheme: Sendable {
    let keyword: NSColor
    let string: NSColor
    let comment: NSColor
    let number: NSColor
    let type: NSColor
    let functionCall: NSColor
    let operator_: NSColor
    let punctuation: NSColor
    let latexCommand: NSColor
    let latexMathBackground: NSColor
    let plain: NSColor

    func color(for tokenType: TokenType) -> NSColor {
        switch tokenType {
        case .keyword: return keyword
        case .string: return string
        case .comment: return comment
        case .number: return number
        case .type: return type
        case .functionCall: return functionCall
        case .operator_: return operator_
        case .punctuation: return punctuation
        case .latexCommand: return latexCommand
        case .latexMathInline, .latexMathBlock: return plain
        case .plain: return plain
        }
    }

    func backgroundColor(for tokenType: TokenType) -> NSColor? {
        switch tokenType {
        case .latexMathInline, .latexMathBlock:
            return latexMathBackground
        default:
            return nil
        }
    }
}

struct SyntaxHighlighter {

    // MARK: - Themes

    static let lightTheme = SyntaxTheme(
        keyword: NSColor(red: 0.13, green: 0.13, blue: 0.73, alpha: 1.0),
        string: NSColor(red: 0.15, green: 0.50, blue: 0.15, alpha: 1.0),
        comment: NSColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0),
        number: NSColor(red: 0.0, green: 0.45, blue: 0.45, alpha: 1.0),
        type: NSColor(red: 0.43, green: 0.15, blue: 0.60, alpha: 1.0),
        functionCall: NSColor(red: 0.60, green: 0.30, blue: 0.0, alpha: 1.0),
        operator_: NSColor(red: 0.55, green: 0.10, blue: 0.10, alpha: 1.0),
        punctuation: NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0),
        latexCommand: NSColor(red: 0.50, green: 0.30, blue: 0.10, alpha: 1.0),
        latexMathBackground: NSColor.systemOrange.withAlphaComponent(0.08),
        plain: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    )

    static let darkTheme = SyntaxTheme(
        keyword: NSColor(red: 0.40, green: 0.55, blue: 1.0, alpha: 1.0),
        string: NSColor(red: 0.35, green: 0.75, blue: 0.35, alpha: 1.0),
        comment: NSColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 1.0),
        number: NSColor(red: 0.30, green: 0.80, blue: 0.80, alpha: 1.0),
        type: NSColor(red: 0.70, green: 0.50, blue: 0.90, alpha: 1.0),
        functionCall: NSColor(red: 0.90, green: 0.70, blue: 0.30, alpha: 1.0),
        operator_: NSColor(red: 0.90, green: 0.40, blue: 0.40, alpha: 1.0),
        punctuation: NSColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1.0),
        latexCommand: NSColor(red: 0.85, green: 0.70, blue: 0.40, alpha: 1.0),
        latexMathBackground: NSColor.systemOrange.withAlphaComponent(0.10),
        plain: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    )

    static var currentTheme: SyntaxTheme {
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? darkTheme : lightTheme
    }

    // MARK: - Grammar registry

    private static let grammars: [DetectedLanguage: any SyntaxGrammar.Type] = [
        .swift: SwiftGrammar.self,
        .javascript: JavaScriptGrammar.self,
        .typescript: TypeScriptGrammar.self,
        .jsx: JavaScriptGrammar.self,
        .tsx: TypeScriptGrammar.self,
        .python: PythonGrammar.self,
        .rust: RustGrammar.self,
        .go: GoGrammar.self,
        .shell: ShellGrammar.self,
        .json: JSONGrammar.self,
        .yaml: YAMLGrammar.self,
        .html: HTMLGrammar.self,
        .css: CSSGrammar.self,
        .latex: LaTeXGrammar.self,
        .markdown: MarkdownGrammar.self,
        .plainText: GenericGrammar.self,
    ]

    // MARK: - Highlight

    static func highlight(_ source: String, language: DetectedLanguage) -> [HighlightToken] {
        let grammar = grammars[language] ?? GenericGrammar.self
        return grammar.tokenize(source)
    }

    static func applyHighlighting(to textStorage: NSMutableAttributedString, tokens: [HighlightToken], source: String, theme: SyntaxTheme) {
        for token in tokens {
            let nsRange = NSRange(token.range, in: source)
            let color = theme.color(for: token.type)
            textStorage.addAttribute(.foregroundColor, value: color, range: nsRange)

            if token.type == .comment {
                textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: nsRange)
            } else if token.type == .keyword {
                textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold), range: nsRange)
            }

            if let bgColor = theme.backgroundColor(for: token.type) {
                textStorage.addAttribute(.backgroundColor, value: bgColor, range: nsRange)
            }
        }
    }
}
