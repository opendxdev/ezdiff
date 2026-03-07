import Foundation

enum TokenType: Sendable {
    case keyword
    case string
    case comment
    case number
    case type
    case functionCall
    case operator_
    case punctuation
    case latexCommand
    case latexMathInline
    case latexMathBlock
    case plain
}

struct HighlightToken: Sendable {
    let range: Range<String.Index>
    let type: TokenType
}

protocol SyntaxGrammar {
    static var languageID: String { get }
    static func tokenize(_ source: String) -> [HighlightToken]
}
