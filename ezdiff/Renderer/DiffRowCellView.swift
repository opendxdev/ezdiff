import AppKit

final class DiffRowCellView: NSTableCellView, NSTextFieldDelegate {

    static let identifier = NSUserInterfaceItemIdentifier("DiffRowCell")

    private let editIndicatorStrip = NSView()
    private let gutterLabel = NSTextField(labelWithString: "")
    private let separator = NSView()
    private let textField_ = NSTextField(labelWithString: "")
    private let doneButton = NSButton()

    var onEditCommit: ((String) -> Void)?
    var onTextChanged: (() -> Void)?
    var currentText: String { textField_.stringValue }
    private var isEditing = false
    private var suppressEndEditing = false
    private var plainText = ""

    // Constraint references for dynamic edit padding
    private var gutterTopConstraint: NSLayoutConstraint!
    private var gutterBottomConstraint: NSLayoutConstraint!
    private var textTopConstraint: NSLayoutConstraint!
    private var textBottomConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // Edit indicator strip (hidden by default)
        editIndicatorStrip.wantsLayer = true
        editIndicatorStrip.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        editIndicatorStrip.isHidden = true
        editIndicatorStrip.translatesAutoresizingMaskIntoConstraints = false
        addSubview(editIndicatorStrip)

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
        textField_.isSelectable = false
        textField_.isBordered = false
        textField_.drawsBackground = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.translatesAutoresizingMaskIntoConstraints = false
        textField_.delegate = self
        addSubview(textField_)

        // Done button (hidden by default)
        doneButton.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Done")
        doneButton.bezelStyle = .inline
        doneButton.isBordered = false
        doneButton.isHidden = true
        doneButton.target = self
        doneButton.action = #selector(doneButtonClicked)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(doneButton)

        let gutterWidth = Constants.Cell.gutterWidth
        let vPad = Constants.Cell.verticalPadding / 2
        let stripWidth = Constants.EditMode.indicatorStripWidth
        let doneSize = Constants.EditMode.doneButtonSize

        gutterTopConstraint = gutterLabel.topAnchor.constraint(equalTo: topAnchor, constant: vPad)
        gutterBottomConstraint = gutterLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad)
        textTopConstraint = textField_.topAnchor.constraint(equalTo: topAnchor, constant: vPad)
        textBottomConstraint = textField_.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad)

        NSLayoutConstraint.activate([
            // Edit indicator strip
            editIndicatorStrip.leadingAnchor.constraint(equalTo: leadingAnchor),
            editIndicatorStrip.widthAnchor.constraint(equalToConstant: stripWidth),
            editIndicatorStrip.topAnchor.constraint(equalTo: topAnchor),
            editIndicatorStrip.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Gutter
            gutterLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: stripWidth),
            gutterLabel.widthAnchor.constraint(equalToConstant: gutterWidth - Constants.Cell.gutterInset - stripWidth),
            gutterTopConstraint,
            gutterBottomConstraint,

            // Separator
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: gutterWidth),
            separator.widthAnchor.constraint(equalToConstant: Constants.Cell.separatorWidth),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Text field
            textField_.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: Constants.Cell.textLeadingMargin),
            textField_.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -4),
            textTopConstraint,
            textBottomConstraint,

            // Done button
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.Cell.textTrailingMargin),
            doneButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: doneSize),
            doneButton.heightAnchor.constraint(equalToConstant: doneSize),
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

        // Store plain text for editing
        plainText = row.text

        // Text
        if !isEditing {
            textField_.attributedStringValue = attributedText
        }

        // Background
        wantsLayer = true
        if row.isPlaceholder {
            layer?.backgroundColor = appearance.placeholderBackground.cgColor
        } else {
            let bgColor = appearance.diffLineBackground(for: row.diffType)
            layer?.backgroundColor = bgColor == .clear ? nil : bgColor.cgColor
        }
    }

    // MARK: - Inline Editing

    func enterEditMode() {
        guard !isEditing else { return }
        isEditing = true

        // Text field edit styling
        textField_.isSelectable = true
        textField_.isEditable = true
        textField_.lineBreakMode = .byWordWrapping
        textField_.cell?.truncatesLastVisibleLine = false
        textField_.isBordered = false
        textField_.drawsBackground = true
        textField_.backgroundColor = .textBackgroundColor
        textField_.font = AppearanceManager.shared.codeFont
        textField_.textColor = .textColor
        textField_.stringValue = plainText

        // Rounded border + shadow via layer
        textField_.wantsLayer = true
        textField_.layer?.cornerRadius = Constants.EditMode.textFieldCornerRadius
        textField_.layer?.borderWidth = Constants.EditMode.textFieldBorderWidth
        textField_.layer?.borderColor = AppearanceManager.shared.editTextFieldBorder.cgColor
        textField_.layer?.shadowColor = NSColor.controlAccentColor.cgColor
        textField_.layer?.shadowOpacity = 0.15
        textField_.layer?.shadowRadius = 2
        textField_.layer?.shadowOffset = .zero
        textField_.layer?.masksToBounds = false

        // Visual indicators
        editIndicatorStrip.isHidden = false
        gutterLabel.textColor = .controlAccentColor
        wantsLayer = true
        layer?.backgroundColor = AppearanceManager.shared.editCellBackground.cgColor

        // Increase padding
        let editVPad = Constants.EditMode.verticalPadding / 2
        gutterTopConstraint.constant = editVPad
        gutterBottomConstraint.constant = -editVPad
        textTopConstraint.constant = editVPad
        textBottomConstraint.constant = -editVPad

        doneButton.contentTintColor = .controlAccentColor
        doneButton.isHidden = false

        suppressEndEditing = true
        textField_.window?.makeFirstResponder(textField_)
        textField_.selectText(nil)
        DispatchQueue.main.async { [weak self] in
            self?.suppressEndEditing = false
        }
    }

    func exitEditMode() {
        guard isEditing else { return }
        isEditing = false

        let newText = textField_.stringValue

        // Reset text field styling
        textField_.isSelectable = false
        textField_.isEditable = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.isBordered = false
        textField_.drawsBackground = false
        textField_.layer?.cornerRadius = 0
        textField_.layer?.borderWidth = 0
        textField_.layer?.shadowOpacity = 0

        // Reset visual indicators
        editIndicatorStrip.isHidden = true
        gutterLabel.textColor = .secondaryLabelColor
        doneButton.isHidden = true

        // Restore normal padding
        let vPad = Constants.Cell.verticalPadding / 2
        gutterTopConstraint.constant = vPad
        gutterBottomConstraint.constant = -vPad
        textTopConstraint.constant = vPad
        textBottomConstraint.constant = -vPad

        onEditCommit?(newText)
    }

    private func resetEditState() {
        isEditing = false
        textField_.isSelectable = false
        textField_.isEditable = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.isBordered = false
        textField_.drawsBackground = false
        textField_.layer?.cornerRadius = 0
        textField_.layer?.borderWidth = 0
        textField_.layer?.shadowOpacity = 0
        editIndicatorStrip.isHidden = true
        gutterLabel.textColor = .secondaryLabelColor
        doneButton.isHidden = true

        let vPad = Constants.Cell.verticalPadding / 2
        gutterTopConstraint.constant = vPad
        gutterBottomConstraint.constant = -vPad
        textTopConstraint.constant = vPad
        textBottomConstraint.constant = -vPad
    }

    @objc private func doneButtonClicked() {
        exitEditMode()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        if isEditing && !suppressEndEditing {
            exitEditMode()
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        if isEditing {
            onTextChanged?()
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            exitEditMode()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape — cancel without committing
            resetEditState()
            return true
        }
        return false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if isEditing {
            resetEditState()
        }
        gutterLabel.stringValue = ""
        textField_.attributedStringValue = NSAttributedString()
        layer?.backgroundColor = nil
        onEditCommit = nil
        onTextChanged = nil
        suppressEndEditing = false
        plainText = ""
    }
}
