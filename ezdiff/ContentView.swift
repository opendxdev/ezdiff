import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var leftFile = DiffFile()
    @StateObject private var rightFile = DiffFile()
    @StateObject private var leftHighlighter = AsyncHighlightPipeline()
    @StateObject private var rightHighlighter = AsyncHighlightPipeline()
    @StateObject private var scrollCoordinator = SyncScrollCoordinator()
    @StateObject private var rowHeightCoordinator = RowHeightCoordinator()

    @State private var diffResult = DiffResult.empty
    @AppStorage(Constants.SettingsKey.displayMode) private var displayModeRaw = DisplayMode.sideBySide.rawValue
    @State private var showPreview = false
    @State private var vimModeEnabled = false
    @AppStorage(Constants.SettingsKey.ignoreWhitespace) private var ignoreWhitespace = false
    @AppStorage(Constants.SettingsKey.wordWrapEnabled) private var wordWrapEnabled = false
    @AppStorage(Constants.SettingsKey.fontSize) private var fontSize: Double = Double(Constants.Font.defaultCodeSize)
    @AppStorage(Constants.SettingsKey.showStatsBar) private var showStatsBar = true
    @State private var diffTask: Task<Void, Never>?
    @State private var focusedSide: PaneSide = .left
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var currentHunkIndex = 0

    private var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeRaw) ?? .sideBySide }
    }

    private var displayModeBinding: Binding<DisplayMode> {
        Binding(
            get: { DisplayMode(rawValue: displayModeRaw) ?? .sideBySide },
            set: { displayModeRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if showStatsBar && !leftFile.isEmpty && !rightFile.isEmpty {
                StatsBarView(
                    stats: diffResult.stats,
                    leftLanguage: leftFile.detectedLanguage,
                    rightLanguage: rightFile.detectedLanguage
                )
            }

            SideBySideView(
                leftFile: leftFile,
                rightFile: rightFile,
                leftTokens: leftHighlighter.tokens,
                rightTokens: rightHighlighter.tokens,
                diffResult: diffResult,
                scrollCoordinator: scrollCoordinator,
                rowHeightCoordinator: rowHeightCoordinator,
                wordWrapEnabled: wordWrapEnabled,
                onLeftFileDrop: { loadFile($0, into: leftFile) },
                onRightFileDrop: { loadFile($0, into: rightFile) },
                onRecentPairSelected: loadRecentPair,
                onClearLeft: { clearFile(leftFile) },
                onClearRight: { clearFile(rightFile) }
            )
        }
        .toolbar {
            ToolbarView(
                displayMode: displayModeBinding,
                ignoreWhitespace: $ignoreWhitespace,
                wordWrapEnabled: $wordWrapEnabled,
                onCopyDiff: copyDiff,
                onExportDiff: exportDiff
            )
        }
        .onChange(of: leftFile.content) { _, _ in
            updateLeftHighlighting()
            recomputeDiffDebounced()
        }
        .onChange(of: rightFile.content) { _, _ in
            updateRightHighlighting()
            recomputeDiffDebounced()
        }
        .onChange(of: ignoreWhitespace) { _, _ in
            recomputeDiffDebounced()
        }
        .onChange(of: fontSize) { _, newSize in
            AppearanceManager.shared.codeFontSize = CGFloat(newSize)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openLeftFile)) { _ in
            openFilePanel { url in loadFile(url, into: leftFile) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRightFile)) { _ in
            openFilePanel { url in loadFile(url, into: rightFile) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveFile)) { _ in
            saveCurrentFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateNextHunk)) { _ in
            navigateHunk(forward: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigatePrevHunk)) { _ in
            navigateHunk(forward: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleDisplayMode)) { _ in
            displayModeRaw = displayMode == .sideBySide ? DisplayMode.unified.rawValue : DisplayMode.sideBySide.rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyDiff)) { _ in
            copyDiff()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportDiff)) { _ in
            exportDiff()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleIgnoreWhitespace)) { _ in
            ignoreWhitespace.toggle()
        }
        .alert("Save Error", isPresented: $showSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    // MARK: - Computed Properties

    private var canShowPreview: Bool {
        let previewLanguages: Set<DetectedLanguage> = [.markdown, .latex]
        return previewLanguages.contains(leftFile.detectedLanguage)
            || previewLanguages.contains(rightFile.detectedLanguage)
    }

    private var focusedFile: DiffFile {
        focusedSide == .left ? leftFile : rightFile
    }

    // MARK: - File Loading

    private func loadFile(_ url: URL, into file: DiffFile) {
        do {
            let loaded = try DiffFile.load(from: url)
            file.url = loaded.url
            file.filename = loaded.filename
            file.content = loaded.content
            file.detectedLanguage = loaded.detectedLanguage
            file.lastModified = loaded.lastModified
            file.hasUnsavedChanges = false

            if !leftFile.isEmpty && !rightFile.isEmpty,
               let leftURL = leftFile.url, let rightURL = rightFile.url {
                RecentPairs.add(left: leftURL, right: rightURL)
            }
        } catch {
            saveErrorMessage = "Failed to load file: \(error.localizedDescription)"
            showSaveError = true
        }
    }

    private func clearFile(_ file: DiffFile) {
        file.clear()
        diffResult = DiffResult.empty
    }

    private func loadRecentPair(_ pair: RecentPair) {
        let leftURL = URL(fileURLWithPath: pair.leftPath)
        let rightURL = URL(fileURLWithPath: pair.rightPath)

        if FileManager.default.fileExists(atPath: pair.leftPath) {
            loadFile(leftURL, into: leftFile)
        }
        if FileManager.default.fileExists(atPath: pair.rightPath) {
            loadFile(rightURL, into: rightFile)
        }
    }

    private func openFilePanel(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }

    // MARK: - Save

    private func saveCurrentFile() {
        let file = focusedFile
        guard !file.isEmpty else { return }

        do {
            if file.url == nil {
                let panel = NSSavePanel()
                panel.nameFieldStringValue = file.filename.isEmpty ? "untitled.txt" : file.filename
                panel.allowedContentTypes = [.plainText]
                guard panel.runModal() == .OK, let url = panel.url else { return }
                file.url = url
                file.filename = url.lastPathComponent
            }
            try file.save()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    // MARK: - Highlighting

    private func updateLeftHighlighting() {
        guard !leftFile.isEmpty else { return }
        leftHighlighter.update(source: leftFile.content, language: leftFile.detectedLanguage)
    }

    private func updateRightHighlighting() {
        guard !rightFile.isEmpty else { return }
        rightHighlighter.update(source: rightFile.content, language: rightFile.detectedLanguage)
    }

    // MARK: - Diff Computation

    private func recomputeDiffDebounced() {
        diffTask?.cancel()
        guard !leftFile.isEmpty && !rightFile.isEmpty else {
            diffResult = DiffResult.empty
            return
        }

        let left = leftFile.content
        let right = rightFile.content
        let ignoreWS = ignoreWhitespace

        diffTask = Task {
            try? await Task.sleep(for: .milliseconds(Constants.Timing.diffDebounceMs))
            guard !Task.isCancelled else { return }

            let result = await Task.detached {
                await DiffEngine.computeDiff(left: left, right: right, ignoreWhitespace: ignoreWS)
            }.value

            self.diffResult = result
            self.currentHunkIndex = 0
        }
    }

    // MARK: - Hunk Navigation

    private func navigateHunk(forward: Bool) {
        let rows = diffResult.hunkStartRows
        guard !rows.isEmpty else { return }

        if forward {
            if currentHunkIndex < rows.count - 1 {
                currentHunkIndex += 1
            } else {
                currentHunkIndex = 0
            }
        } else {
            if currentHunkIndex > 0 {
                currentHunkIndex -= 1
            } else {
                currentHunkIndex = rows.count - 1
            }
        }

        let targetRow = rows[currentHunkIndex]
        scrollCoordinator.scrollToRow(targetRow, rowHeights: rowHeightCoordinator.rowHeights)
    }

    // MARK: - Actions

    private func copyDiff() {
        let diffText = generateUnifiedDiff()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diffText, forType: .string)
    }

    private func exportDiff() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "diff.patch"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            let diffText = generateUnifiedDiff()
            try? diffText.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func generateUnifiedDiff() -> String {
        var output = "--- \(leftFile.filename.isEmpty ? "a" : leftFile.filename)\n"
        output += "+++ \(rightFile.filename.isEmpty ? "b" : rightFile.filename)\n"

        for hunk in diffResult.hunks {
            output += hunk.header + "\n"
            for line in hunk.lines {
                switch line.type {
                case .unchanged:
                    output += " \(line.text)\n"
                case .added:
                    output += "+\(line.text)\n"
                case .removed, .modified:
                    output += "-\(line.text)\n"
                }
            }
        }
        return output
    }
}
