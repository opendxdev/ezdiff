import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.SettingsKey.wordWrapEnabled) private var wordWrapEnabled = false
    @AppStorage(Constants.SettingsKey.ignoreWhitespace) private var ignoreWhitespace = false
    @AppStorage(Constants.SettingsKey.displayMode) private var displayModeRaw = DisplayMode.sideBySide.rawValue
    @AppStorage(Constants.SettingsKey.fontSize) private var fontSize: Double = Double(Constants.Font.defaultCodeSize)
    @AppStorage(Constants.SettingsKey.showStatsBar) private var showStatsBar = true

    var body: some View {
        Form {
            Section("Editor") {
                Toggle("Word Wrap", isOn: $wordWrapEnabled)

                Picker("Display Mode", selection: $displayModeRaw) {
                    Text("Side by Side").tag(DisplayMode.sideBySide.rawValue)
                    Text("Unified").tag(DisplayMode.unified.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section("Diff") {
                Toggle("Ignore Whitespace", isOn: $ignoreWhitespace)
            }

            Section("Appearance") {
                HStack {
                    Text("Font Size")
                    Slider(
                        value: $fontSize,
                        in: Double(Constants.Font.minCodeSize)...Double(Constants.Font.maxCodeSize),
                        step: 1
                    )
                    Text("\(Int(fontSize)) pt")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                Toggle("Show Stats Bar", isOn: $showStatsBar)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
    }
}
