import AppKit

final class UnifiedRowCellView: NSTableCellView {

    static let identifier = NSUserInterfaceItemIdentifier("UnifiedRowCell")

    private let leftGutterLabel = NSTextField(labelWithString: "")
    private let rightGutterLabel = NSTextField(labelWithString: "")
    private let separatorLeft = NSView()
    private let separatorRight = NSView()
    private let prefixLabel = NSTextField(labelWithString: "")
    private let textField_ = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let gutterFont = AppearanceManager.shared.gutterFont
        let gutterWidth = Constants.UnifiedCell.gutterWidth
        let sepWidth = Constants.UnifiedCell.separatorWidth
        let prefixWidth = Constants.UnifiedCell.prefixWidth
        let vPad = Constants.UnifiedCell.verticalPadding / 2

        // Left gutter
        leftGutterLabel.font = gutterFont
        leftGutterLabel.textColor = .secondaryLabelColor
        leftGutterLabel.alignment = .right
        leftGutterLabel.isEditable = false
        leftGutterLabel.isSelectable = false
        leftGutterLabel.isBordered = false
        leftGutterLabel.drawsBackground = false
        leftGutterLabel.lineBreakMode = .byClipping
        leftGutterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftGutterLabel)

        // Separator after left gutter
        separatorLeft.wantsLayer = true
        separatorLeft.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separatorLeft.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLeft)

        // Right gutter
        rightGutterLabel.font = gutterFont
        rightGutterLabel.textColor = .secondaryLabelColor
        rightGutterLabel.alignment = .right
        rightGutterLabel.isEditable = false
        rightGutterLabel.isSelectable = false
        rightGutterLabel.isBordered = false
        rightGutterLabel.drawsBackground = false
        rightGutterLabel.lineBreakMode = .byClipping
        rightGutterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightGutterLabel)

        // Separator after right gutter
        separatorRight.wantsLayer = true
        separatorRight.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separatorRight.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorRight)

        // Prefix label (+, -, ~, space)
        prefixLabel.font = AppearanceManager.shared.codeFont
        prefixLabel.alignment = .center
        prefixLabel.isEditable = false
        prefixLabel.isSelectable = false
        prefixLabel.isBordered = false
        prefixLabel.drawsBackground = false
        prefixLabel.lineBreakMode = .byClipping
        prefixLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(prefixLabel)

        // Text field
        textField_.isEditable = false
        textField_.isSelectable = false
        textField_.isBordered = false
        textField_.drawsBackground = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField_)

        let gutterInset: CGFloat = 4

        NSLayoutConstraint.activate([
            // Left gutter
            leftGutterLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftGutterLabel.widthAnchor.constraint(equalToConstant: gutterWidth - gutterInset),
            leftGutterLabel.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            leftGutterLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),

            // Left separator
            separatorLeft.leadingAnchor.constraint(equalTo: leadingAnchor, constant: gutterWidth),
            separatorLeft.widthAnchor.constraint(equalToConstant: sepWidth),
            separatorLeft.topAnchor.constraint(equalTo: topAnchor),
            separatorLeft.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Right gutter
            rightGutterLabel.leadingAnchor.constraint(equalTo: separatorLeft.trailingAnchor),
            rightGutterLabel.widthAnchor.constraint(equalToConstant: gutterWidth - gutterInset),
            rightGutterLabel.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            rightGutterLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),

            // Right separator
            separatorRight.leadingAnchor.constraint(equalTo: separatorLeft.trailingAnchor, constant: gutterWidth),
            separatorRight.widthAnchor.constraint(equalToConstant: sepWidth),
            separatorRight.topAnchor.constraint(equalTo: topAnchor),
            separatorRight.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Prefix
            prefixLabel.leadingAnchor.constraint(equalTo: separatorRight.trailingAnchor),
            prefixLabel.widthAnchor.constraint(equalToConstant: prefixWidth),
            prefixLabel.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            prefixLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),

            // Text
            textField_.leadingAnchor.constraint(equalTo: prefixLabel.trailingAnchor, constant: Constants.UnifiedCell.textLeadingMargin),
            textField_.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.UnifiedCell.textTrailingMargin),
            textField_.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            textField_.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),
        ])
    }

    func configure(
        row: any DiffRowData,
        attributedText: NSAttributedString,
        appearance: AppearanceManager
    ) {
        // Left gutter (shows left file line number)
        if let num = row.leftLineNumber {
            leftGutterLabel.stringValue = "\(num)"
            leftGutterLabel.textColor = appearance.gutterTextColor
        } else {
            leftGutterLabel.stringValue = ""
        }

        // Right gutter (shows right file line number)
        if let num = row.rightLineNumber {
            rightGutterLabel.stringValue = "\(num)"
            rightGutterLabel.textColor = appearance.gutterTextColor
        } else {
            rightGutterLabel.stringValue = ""
        }

        // Prefix indicator
        switch row.diffType {
        case .added:
            prefixLabel.stringValue = "+"
            prefixLabel.textColor = .systemGreen
        case .removed:
            prefixLabel.stringValue = "−"
            prefixLabel.textColor = .systemRed
        case .modified:
            prefixLabel.stringValue = "~"
            prefixLabel.textColor = .systemOrange
        case .unchanged:
            prefixLabel.stringValue = ""
            prefixLabel.textColor = .secondaryLabelColor
        }

        // Text
        textField_.attributedStringValue = attributedText

        // Background
        wantsLayer = true
        let bgColor = appearance.diffLineBackground(for: row.diffType)
        layer?.backgroundColor = bgColor == .clear ? nil : bgColor.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        leftGutterLabel.stringValue = ""
        rightGutterLabel.stringValue = ""
        prefixLabel.stringValue = ""
        textField_.attributedStringValue = NSAttributedString()
        layer?.backgroundColor = nil
    }
}
