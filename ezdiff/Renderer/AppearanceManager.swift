import AppKit
import Combine

@MainActor
final class AppearanceManager: ObservableObject {

    static let shared = AppearanceManager()

    // MARK: - Fonts

    private(set) var codeFont: NSFont
    private(set) var codeBoldFont: NSFont
    private(set) var gutterFont: NSFont
    private(set) var singleLineHeight: CGFloat

    @Published var codeFontSize: CGFloat = Constants.Font.defaultCodeSize {
        didSet {
            guard codeFontSize != oldValue else { return }
            rebuildFonts()
        }
    }

    // MARK: - Appearance State

    @Published private(set) var isDark: Bool = false
    private var appearanceObserver: NSObjectProtocol?

    private init() {
        let size = Constants.Font.defaultCodeSize
        let gutterSize = max(size - Constants.Font.gutterSizeOffset, Constants.Font.minGutterSize)
        codeFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        codeBoldFont = NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
        gutterFont = NSFont.monospacedSystemFont(ofSize: gutterSize, weight: .regular)
        singleLineHeight = {
            let font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            return ceil(font.ascender - font.descender + font.leading)
        }()
        isDark = Self.detectDark()
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAppearance()
            }
        }
    }

    deinit {
        if let obs = appearanceObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func rebuildFonts() {
        let size = codeFontSize
        let gutterSize = max(size - Constants.Font.gutterSizeOffset, Constants.Font.minGutterSize)
        codeFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        codeBoldFont = NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
        gutterFont = NSFont.monospacedSystemFont(ofSize: gutterSize, weight: .regular)
        singleLineHeight = ceil(codeFont.ascender - codeFont.descender + codeFont.leading)
        objectWillChange.send()
    }

    func refreshAppearance() {
        let newDark = Self.detectDark()
        if newDark != isDark {
            isDark = newDark
        }
    }

    private static func detectDark() -> Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // MARK: - Syntax Theme

    var syntaxTheme: SyntaxTheme {
        isDark ? SyntaxHighlighter.darkTheme : SyntaxHighlighter.lightTheme
    }

    // MARK: - Diff Line Background Colors

    func diffLineBackground(for type: DiffLineType) -> NSColor {
        switch type {
        case .unchanged: return .clear
        case .added: return NSColor.systemGreen.withAlphaComponent(Constants.Alpha.addedLineBackground)
        case .removed: return NSColor.systemRed.withAlphaComponent(Constants.Alpha.removedLineBackground)
        case .modified: return NSColor.systemOrange.withAlphaComponent(Constants.Alpha.modifiedLineBackground)
        }
    }

    // MARK: - Diff Word Background Colors

    func diffWordBackground(for type: DiffWordType) -> NSColor {
        switch type {
        case .unchanged: return .clear
        case .added: return NSColor.systemGreen.withAlphaComponent(Constants.Alpha.addedWordHighlight)
        case .removed: return NSColor.systemRed.withAlphaComponent(Constants.Alpha.removedWordHighlight)
        }
    }

    // MARK: - Gutter Colors

    var gutterBackground: NSColor { .controlBackgroundColor }
    var gutterSeparator: NSColor { .separatorColor }
    var gutterTextColor: NSColor { .secondaryLabelColor }

    // MARK: - Placeholder Row

    var placeholderBackground: NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(Constants.Alpha.placeholderBackground)
            : NSColor.black.withAlphaComponent(Constants.Alpha.placeholderBackground)
    }

    var placeholderStripeColor: NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(Constants.Alpha.placeholderStripe)
            : NSColor.black.withAlphaComponent(Constants.Alpha.placeholderStripe)
    }

    // MARK: - Default Text Color

    var defaultTextColor: NSColor { .textColor }

    // MARK: - Edit Mode Colors

    var editIndicatorColor: NSColor { .controlAccentColor }
    var editCellBackground: NSColor { .controlAccentColor.withAlphaComponent(Constants.EditMode.backgroundAlpha) }
    var editTextFieldBorder: NSColor { .controlAccentColor.withAlphaComponent(0.5) }
}
