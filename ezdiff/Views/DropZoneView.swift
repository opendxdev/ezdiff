import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let onFileDrop: (URL) -> Void
    let onRecentPairSelected: ((RecentPair) -> Void)?
    @State private var isTargeted = false

    init(onFileDrop: @escaping (URL) -> Void, onRecentPairSelected: ((RecentPair) -> Void)? = nil) {
        self.onFileDrop = onFileDrop
        self.onRecentPairSelected = onRecentPairSelected
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Drop a file here")
                .font(.title2)
                .fontWeight(.medium)

            Text("or click to open")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            recentSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.5))
        )
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            openFilePanel()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        let recentPairs = RecentPairs.pairs
        if !recentPairs.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                ForEach(recentPairs) { pair in
                    Button {
                        if let callback = onRecentPairSelected {
                            callback(pair)
                        } else {
                            let url = URL(fileURLWithPath: pair.leftPath)
                            if FileManager.default.fileExists(atPath: pair.leftPath) {
                                onFileDrop(url)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc")
                                .font(.caption2)
                            Text("\(pair.leftFilename) \u{2194} \(pair.rightFilename)")
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            onFileDrop(url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }
            DispatchQueue.main.async {
                onFileDrop(url)
            }
        }
        return true
    }
}
