import SwiftUI

struct DraggableDivider: View {
    @State private var isHovered = false

    var body: some View {
        Rectangle()
            .fill(isHovered ? Color.accentColor.opacity(0.3) : Color(nsColor: .separatorColor))
            .frame(width: Constants.PaneDivider.width)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
