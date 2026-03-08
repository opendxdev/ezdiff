import Foundation

enum Constants {

    // MARK: - Cell Layout

    enum Cell {
        static let gutterWidth: CGFloat = 44
        static let gutterInset: CGFloat = 8
        static let textLeadingMargin: CGFloat = 8
        static let textTrailingMargin: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let intercellSpacing: CGFloat = 1
        static let separatorWidth: CGFloat = 1
    }

    // MARK: - Header Bar

    enum Header {
        static let hStackSpacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let badgeHPadding: CGFloat = 8
        static let badgeVPadding: CGFloat = 3
        static let badgeCornerRadius: CGFloat = 4
    }

    // MARK: - Stats Bar

    enum Stats {
        static let hStackSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 6
    }

    // MARK: - Drop Zone

    enum DropZone {
        static let cornerRadius: CGFloat = 12
        static let dashLength: CGFloat = 8
        static let dashGap: CGFloat = 4
        static let lineWidth: CGFloat = 2
        static let iconSize: CGFloat = 48
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 16
    }

    // MARK: - Fonts

    enum Font {
        static let defaultCodeSize: CGFloat = 13
        static let minCodeSize: CGFloat = 10
        static let maxCodeSize: CGFloat = 24
        static let gutterSizeOffset: CGFloat = 2
        static let minGutterSize: CGFloat = 9
    }

    // MARK: - Timing

    enum Timing {
        static let diffDebounceMs: Int = 150
        static let highlightDebounceMs: Int = 100
    }

    // MARK: - Capacities

    enum Capacity {
        static let attributedStringCache: Int = 500
        static let maxRecentPairs: Int = 5
        static let binaryCheckBytes: Int = 8192
        static let diffContextLines: Int = 3
    }

    // MARK: - Diff Colors (alpha values)

    enum Alpha {
        static let addedLineBackground: CGFloat = 0.12
        static let removedLineBackground: CGFloat = 0.12
        static let modifiedLineBackground: CGFloat = 0.10
        static let addedWordHighlight: CGFloat = 0.25
        static let removedWordHighlight: CGFloat = 0.25
        static let placeholderBackground: CGFloat = 0.03
        static let placeholderStripe: CGFloat = 0.05
        static let latexMathBackgroundLight: CGFloat = 0.08
        static let latexMathBackgroundDark: CGFloat = 0.10
    }

    // MARK: - Settings Keys (UserDefaults)

    enum SettingsKey {
        static let wordWrapEnabled = "wordWrapEnabled"
        static let ignoreWhitespace = "ignoreWhitespace"
        static let displayMode = "displayMode"
        static let fontSize = "fontSize"
        static let showStatsBar = "showStatsBar"
    }

    // MARK: - Animation

    enum Animation {
        static let scrollDuration: Double = 0.3
    }
}
