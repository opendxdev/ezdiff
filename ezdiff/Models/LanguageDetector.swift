import Foundation

enum CommentStyle: Sendable {
    case cStyle          // // and /* */
    case hash            // #
    case doubleDash      // --
    case percent         // %
    case htmlStyle       // <!-- -->
    case none

    var singleLine: String? {
        switch self {
        case .cStyle: return "//"
        case .hash: return "#"
        case .doubleDash: return "--"
        case .percent: return "%"
        case .htmlStyle, .none: return nil
        }
    }

    var multiLineOpen: String? {
        switch self {
        case .cStyle: return "/*"
        case .htmlStyle: return "<!--"
        default: return nil
        }
    }

    var multiLineClose: String? {
        switch self {
        case .cStyle: return "*/"
        case .htmlStyle: return "-->"
        default: return nil
        }
    }
}

struct BracketPair: Sendable {
    let open: Character
    let close: Character
}

enum DetectedLanguage: String, CaseIterable, Identifiable, Sendable {
    case swift
    case javascript
    case typescript
    case jsx
    case tsx
    case python
    case rust
    case go
    case shell
    case json
    case yaml
    case html
    case css
    case latex
    case markdown
    case plainText

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .jsx: return "JSX"
        case .tsx: return "TSX"
        case .python: return "Python"
        case .rust: return "Rust"
        case .go: return "Go"
        case .shell: return "Shell"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .html: return "HTML"
        case .css: return "CSS"
        case .latex: return "LaTeX"
        case .markdown: return "Markdown"
        case .plainText: return "Plain Text"
        }
    }

    var extensions: [String] {
        switch self {
        case .swift: return [".swift"]
        case .javascript: return [".js", ".mjs", ".cjs"]
        case .typescript: return [".ts", ".mts", ".cts"]
        case .jsx: return [".jsx"]
        case .tsx: return [".tsx"]
        case .python: return [".py", ".pyw", ".pyi"]
        case .rust: return [".rs"]
        case .go: return [".go"]
        case .shell: return [".sh", ".bash", ".zsh", ".fish"]
        case .json: return [".json", ".jsonc"]
        case .yaml: return [".yml", ".yaml"]
        case .html: return [".html", ".htm", ".xhtml"]
        case .css: return [".css", ".scss", ".less"]
        case .latex: return [".tex", ".ltx", ".sty", ".cls"]
        case .markdown: return [".md", ".markdown", ".mdown", ".mkd"]
        case .plainText: return [".txt"]
        }
    }

    var commentStyle: CommentStyle {
        switch self {
        case .swift, .javascript, .typescript, .jsx, .tsx, .rust, .go, .css:
            return .cStyle
        case .python, .shell, .yaml:
            return .hash
        case .latex:
            return .percent
        case .html:
            return .htmlStyle
        case .json, .markdown, .plainText:
            return .none
        }
    }

    var bracketPairs: [BracketPair] {
        switch self {
        case .swift, .javascript, .typescript, .jsx, .tsx, .rust, .go, .css:
            return [
                BracketPair(open: "(", close: ")"),
                BracketPair(open: "[", close: "]"),
                BracketPair(open: "{", close: "}"),
            ]
        case .python:
            return [
                BracketPair(open: "(", close: ")"),
                BracketPair(open: "[", close: "]"),
                BracketPair(open: "{", close: "}"),
            ]
        case .json:
            return [
                BracketPair(open: "[", close: "]"),
                BracketPair(open: "{", close: "}"),
            ]
        case .html:
            return [
                BracketPair(open: "<", close: ">"),
            ]
        case .latex:
            return [
                BracketPair(open: "{", close: "}"),
                BracketPair(open: "[", close: "]"),
            ]
        case .shell, .yaml, .markdown, .plainText:
            return []
        }
    }
}

struct LanguageDetector: Sendable {

    static func detect(filename: String, content: String) -> DetectedLanguage {
        // 1. Extension matching
        let ext = "." + (filename.split(separator: ".").last.map(String.init) ?? "")
        for lang in DetectedLanguage.allCases where lang != .plainText {
            if lang.extensions.contains(ext.lowercased()) {
                return lang
            }
        }

        // 2. Filename matching
        let name = (filename as NSString).lastPathComponent.lowercased()
        switch name {
        case "makefile", "gnumakefile":
            return .shell
        case "dockerfile":
            return .shell
        case "podfile", "gemfile", "rakefile":
            return .shell
        case ".gitignore", ".dockerignore", ".editorconfig":
            return .plainText
        case "package.json", "tsconfig.json", "jsconfig.json":
            return .json
        case ".bashrc", ".bash_profile", ".zshrc", ".zshenv", ".profile":
            return .shell
        default:
            break
        }

        // 3. Shebang detection
        let firstLine = content.prefix(256).split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
        if firstLine.hasPrefix("#!") {
            let shebang = firstLine.lowercased()
            if shebang.contains("python") { return .python }
            if shebang.contains("node") || shebang.contains("deno") || shebang.contains("bun") { return .javascript }
            if shebang.contains("bash") || shebang.contains("/sh") || shebang.contains("zsh") { return .shell }
            if shebang.contains("ruby") { return .shell }
            if shebang.contains("perl") { return .shell }
        }

        // 4. Content heuristics
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("\\documentclass") || trimmed.hasPrefix("\\usepackage") || trimmed.contains("\\begin{document}") {
            return .latex
        }
        if trimmed.hasPrefix("<!DOCTYPE") || trimmed.hasPrefix("<html") || trimmed.hasPrefix("<!doctype") {
            return .html
        }
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            // Could be JSON - check for valid-looking JSON structure
            if trimmed.contains(":") && (trimmed.contains("\"") || trimmed.contains("'")) {
                return .json
            }
        }
        if trimmed.hasPrefix("---") && trimmed.contains(":") {
            return .yaml
        }

        // 5. Fallback
        return .plainText
    }
}
