import AppKit

final class DiffRowCellView: NSTableCellView, NSTextFieldDelegate {

    static let identifier = NSUserInterfaceItemIdentifier("DiffRowCell")

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
            textField_.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -4),
            textField_.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            textField_.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),

            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.Cell.textTrailingMargin),
            doneButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 20),
            doneButton.heightAnchor.constraint(equalToConstant: 20),
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

        textField_.isSelectable = true
        textField_.isEditable = true
        textField_.lineBreakMode = .byWordWrapping
        textField_.cell?.truncatesLastVisibleLine = false
        textField_.isBordered = true
        textField_.drawsBackground = true
        textField_.backgroundColor = .textBackgroundColor
        textField_.font = AppearanceManager.shared.codeFont
        textField_.textColor = .textColor
        textField_.stringValue = plainText

        // Visual edit indicator
        gutterLabel.textColor = .controlAccentColor
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.06).cgColor

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
        textField_.isSelectable = false
        textField_.isEditable = false
        textField_.lineBreakMode = .byClipping
        textField_.cell?.truncatesLastVisibleLine = true
        textField_.isBordered = false
        textField_.drawsBackground = false

        gutterLabel.textColor = .secondaryLabelColor

        doneButton.isHidden = true

        onEditCommit?(newText)
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
            isEditing = false
            textField_.isSelectable = false
            textField_.isEditable = false
            textField_.lineBreakMode = .byClipping
            textField_.cell?.truncatesLastVisibleLine = true
            textField_.isBordered = false
            textField_.drawsBackground = false
            gutterLabel.textColor = .secondaryLabelColor
            doneButton.isHidden = true
            return true
        }
        return false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if isEditing {
            isEditing = false
            textField_.isSelectable = false
            textField_.isEditable = false
            textField_.lineBreakMode = .byClipping
            textField_.cell?.truncatesLastVisibleLine = true
            textField_.isBordered = false
            textField_.drawsBackground = false
            gutterLabel.textColor = .secondaryLabelColor
            doneButton.isHidden = true
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
