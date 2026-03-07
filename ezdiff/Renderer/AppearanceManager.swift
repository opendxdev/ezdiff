import AppKit
import Combine

@MainActor
final class AppearanceManager: ObservableObject {

    static let shared = AppearanceManager()

    // MARK: - Fonts

    let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    let codeBoldFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)
    let gutterFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)

    let singleLineHeight: CGFloat
    static let gutterWidth: CGFloat = 44

    // MARK: - Appearance State

    @Published private(set) var isDark: Bool = false
    private var appearanceObserver: NSObjectProtocol?

    private init() {
        singleLineHeight = {
            let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
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
        case .added: return NSColor.systemGreen.withAlphaComponent(0.12)
        case .removed: return NSColor.systemRed.withAlphaComponent(0.12)
        case .modified: return NSColor.systemOrange.withAlphaComponent(0.10)
        }
    }

    // MARK: - Diff Word Background Colors

    func diffWordBackground(for type: DiffWordType) -> NSColor {
        switch type {
        case .unchanged: return .clear
        case .added: return NSColor.systemGreen.withAlphaComponent(0.25)
        case .removed: return NSColor.systemRed.withAlphaComponent(0.25)
        }
    }

    // MARK: - Gutter Colors

    var gutterBackground: NSColor { .controlBackgroundColor }
    var gutterSeparator: NSColor { .separatorColor }
    var gutterTextColor: NSColor { .secondaryLabelColor }

    // MARK: - Placeholder Row

    var placeholderBackground: NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(0.03)
            : NSColor.black.withAlphaComponent(0.03)
    }

    var placeholderStripeColor: NSColor {
        isDark
            ? NSColor.white.withAlphaComponent(0.05)
            : NSColor.black.withAlphaComponent(0.05)
    }

    // MARK: - Default Text Color

    var defaultTextColor: NSColor { .textColor }
}
