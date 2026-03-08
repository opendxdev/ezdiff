import AppKit

final class DiffRowCellView: NSTableCellView {

    static let identifier = NSUserInterfaceItemIdentifier("DiffRowCell")

    private let gutterLabel = NSTextField(labelWithString: "")
    private let separator = NSView()
    private let textField_ = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // Gutter label
        gutterLabel.font = AppearanceManager.shared.gutterFont
        gutterLabel.textColor = .secondaryLabelColor
        gutterLabel.alignment = .right
        gutterLabel.isEditable = false
        gutterLabel.isSelectable = false
        gutterLabel.isBordered = false
        gutterLabel.drawsBackground = false
        gutterLabel.lineBreakMode = .byClipping
        gutterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gutterLabel)

        // Separator
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        // Text field
        textField_.isEditable = false
        textField_.isSelectable = true
        textField_.isBordered = false
        textField_.drawsBackground = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField_)

        let gutterWidth = Constants.Cell.gutterWidth
        let vPad = Constants.Cell.verticalPadding / 2

        NSLayoutConstraint.activate([
            gutterLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            gutterLabel.widthAnchor.constraint(equalToConstant: gutterWidth - Constants.Cell.gutterInset),
            gutterLabel.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            gutterLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: gutterWidth),
            separator.widthAnchor.constraint(equalToConstant: Constants.Cell.separatorWidth),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),

            textField_.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: Constants.Cell.textLeadingMargin),
            textField_.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.Cell.textTrailingMargin),
            textField_.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            textField_.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),
        ])
    }

    func configure(
        row: any DiffRowData,
        attributedText: NSAttributedString,
        appearance: AppearanceManager
    ) {
        // Gutter
        if let num = row.lineNumber {
            gutterLabel.stringValue = "\(num)"
            gutterLabel.textColor = appearance.gutterTextColor
        } else {
            gutterLabel.stringValue = ""
        }

        // Text
        textField_.attributedStringValue = attributedText

        // Background
        wantsLayer = true
        if row.isPlaceholder {
            layer?.backgroundColor = appearance.placeholderBackground.cgColor
        } else {
            let bgColor = appearance.diffLineBackground(for: row.diffType)
            layer?.backgroundColor = bgColor == .clear ? nil : bgColor.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gutterLabel.stringValue = ""
        textField_.attributedStringValue = NSAttributedString()
        layer?.backgroundColor = nil
    }
}
