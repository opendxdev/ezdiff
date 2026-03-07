import Testing
@testable import ezdiff

struct LanguageDetectorTests {

    // MARK: - Extension detection

    @Test func detectSwiftByExtension() {
        let result = LanguageDetector.detect(filename: "main.swift", content: "")
        #expect(result == .swift)
    }

    @Test func detectPythonByExtension() {
        let result = LanguageDetector.detect(filename: "script.py", content: "")
        #expect(result == .python)
    }

    @Test func detectTypeScriptByExtension() {
        let result = LanguageDetector.detect(filename: "app.ts", content: "")
        #expect(result == .typescript)
    }

    @Test func detectTSXByExtension() {
        let result = LanguageDetector.detect(filename: "Component.tsx", content: "")
        #expect(result == .tsx)
    }

    @Test func detectJSXByExtension() {
        let result = LanguageDetector.detect(filename: "Component.jsx", content: "")
        #expect(result == .jsx)
    }

    @Test func detectRustByExtension() {
        let result = LanguageDetector.detect(filename: "lib.rs", content: "")
        #expect(result == .rust)
    }

    @Test func detectGoByExtension() {
        let result = LanguageDetector.detect(filename: "main.go", content: "")
        #expect(result == .go)
    }

    @Test func detectShellByExtension() {
        let result = LanguageDetector.detect(filename: "deploy.sh", content: "")
        #expect(result == .shell)
    }

    @Test func detectJSONByExtension() {
        let result = LanguageDetector.detect(filename: "config.json", content: "")
        #expect(result == .json)
    }

    @Test func detectYAMLByExtension() {
        let result = LanguageDetector.detect(filename: "docker-compose.yml", content: "")
        #expect(result == .yaml)
    }

    @Test func detectHTMLByExtension() {
        let result = LanguageDetector.detect(filename: "index.html", content: "")
        #expect(result == .html)
    }

    @Test func detectCSSByExtension() {
        let result = LanguageDetector.detect(filename: "styles.css", content: "")
        #expect(result == .css)
    }

    @Test func detectLaTeXByExtension() {
        let result = LanguageDetector.detect(filename: "paper.tex", content: "")
        #expect(result == .latex)
    }

    @Test func detectMarkdownByExtension() {
        let result = LanguageDetector.detect(filename: "README.md", content: "")
        #expect(result == .markdown)
    }

    // MARK: - Filename detection

    @Test func detectMakefile() {
        let result = LanguageDetector.detect(filename: "Makefile", content: "")
        #expect(result == .shell)
    }

    @Test func detectDockerfile() {
        let result = LanguageDetector.detect(filename: "Dockerfile", content: "")
        #expect(result == .shell)
    }

    @Test func detectBashRC() {
        let result = LanguageDetector.detect(filename: ".bashrc", content: "")
        #expect(result == .shell)
    }

    // MARK: - Shebang detection

    @Test func detectPythonByShebang() {
        let result = LanguageDetector.detect(filename: "script", content: "#!/usr/bin/env python3\nprint('hello')")
        #expect(result == .python)
    }

    @Test func detectBashByShebang() {
        let result = LanguageDetector.detect(filename: "run", content: "#!/bin/bash\necho hello")
        #expect(result == .shell)
    }

    @Test func detectNodeByShebang() {
        let result = LanguageDetector.detect(filename: "server", content: "#!/usr/bin/env node\nconsole.log('hi')")
        #expect(result == .javascript)
    }

    // MARK: - Content heuristic detection

    @Test func detectLaTeXByContent() {
        let result = LanguageDetector.detect(filename: "file", content: "\\documentclass{article}\n\\begin{document}\nHello\n\\end{document}")
        #expect(result == .latex)
    }

    @Test func detectHTMLByDoctype() {
        let result = LanguageDetector.detect(filename: "page", content: "<!DOCTYPE html>\n<html>\n<body></body>\n</html>")
        #expect(result == .html)
    }

    @Test func detectJSONByContent() {
        let result = LanguageDetector.detect(filename: "data", content: "{\"key\": \"value\"}")
        #expect(result == .json)
    }

    @Test func detectYAMLByContent() {
        let result = LanguageDetector.detect(filename: "config", content: "---\nname: test\nversion: 1")
        #expect(result == .yaml)
    }

    // MARK: - Fallback

    @Test func detectPlainTextFallback() {
        let result = LanguageDetector.detect(filename: "notes", content: "Just some random text without any special markers.")
        #expect(result == .plainText)
    }
}
