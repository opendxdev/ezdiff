import SwiftUI

enum DisplayMode: String {
    case sideBySide
    case unified
}

struct ActionBarView: View {
    @Binding var displayMode: DisplayMode
    @Binding var ignoreWhitespace: Bool
    @Binding var wordWrapEnabled: Bool
    let onCopyDiff: () -> Void
    let onExportDiff: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let canUndo: Bool
    let canRedo: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Constants.ActionBar.buttonSpacing) {
                // Undo / Redo
                ActionBarButton(
                    icon: Constants.ActionBar.undoIcon,
                    label: Constants.ActionBar.undoLabel,
                    action: onUndo,
                    disabled: !canUndo
                )
                ActionBarButton(
                    icon: Constants.ActionBar.redoIcon,
                    label: Constants.ActionBar.redoLabel,
                    action: onRedo,
                    disabled: !canRedo
                )

                verticalDivider

                // Display mode
                ActionBarButton(
                    icon: displayMode == .sideBySide ? Constants.ActionBar.unifiedIcon : Constants.ActionBar.sideBySideIcon,
                    label: displayMode == .sideBySide ? Constants.ActionBar.unifiedLabel : Constants.ActionBar.sideBySideLabel,
                    action: {
                        displayMode = displayMode == .sideBySide ? .unified : .sideBySide
                    }
                )

                verticalDivider

                // Toggles
                ActionBarToggle(
                    icon: wordWrapEnabled ? Constants.ActionBar.wrapOnIcon : Constants.ActionBar.wrapOffIcon,
                    label: Constants.ActionBar.wrapLabel,
                    isOn: $wordWrapEnabled
                )
                ActionBarToggle(
                    icon: ignoreWhitespace ? Constants.ActionBar.whitespaceOnIcon : Constants.ActionBar.whitespaceOffIcon,
                    label: Constants.ActionBar.whitespaceLabel,
                    isOn: $ignoreWhitespace
                )

                Spacer()

                // Actions
                ActionBarButton(
                    icon: Constants.ActionBar.copyIcon,
                    label: Constants.ActionBar.copyLabel,
                    action: onCopyDiff
                )
                ActionBarButton(
                    icon: Constants.ActionBar.exportIcon,
                    label: Constants.ActionBar.exportLabel,
                    action: onExportDiff
                )
            }
            .padding(.horizontal, Constants.ActionBar.horizontalPadding)
            .padding(.vertical, 4)
        }
        .background(.bar)
    }

    private var verticalDivider: some View {
        Divider()
            .frame(height: Constants.ActionBar.dividerHeight)
            .padding(.horizontal, 4)
    }
}

// MARK: - Action Bar Button

private struct ActionBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var disabled: Bool = false

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: Constants.ActionBar.iconSize))
                Text(label)
                    .font(.caption2)
            }
            .frame(minWidth: Constants.ActionBar.buttonMinWidth)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: Constants.ActionBar.buttonCornerRadius)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Action Bar Toggle

private struct ActionBarToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    @State private var isHovering = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(spacing: 1) {
                Image(systemName: icon)
                    .font(.system(size: Constants.ActionBar.iconSize))
                Text(label)
                    .font(.caption2)
            }
            .frame(minWidth: Constants.ActionBar.buttonMinWidth)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .foregroundStyle(isOn ? Color.accentColor : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: Constants.ActionBar.buttonCornerRadius)
                    .fill(isOn ? Color.accentColor.opacity(0.12) : (isHovering ? Color.primary.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
