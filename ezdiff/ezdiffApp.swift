import SwiftUI

extension Notification.Name {
    static let openLeftFile = Notification.Name("dev.opendx.ezdiff.openLeftFile")
    static let openRightFile = Notification.Name("dev.opendx.ezdiff.openRightFile")
    static let saveFile = Notification.Name("dev.opendx.ezdiff.saveFile")
    static let navigateNextHunk = Notification.Name("dev.opendx.ezdiff.navigateNextHunk")
    static let navigatePrevHunk = Notification.Name("dev.opendx.ezdiff.navigatePrevHunk")
    static let toggleDisplayMode = Notification.Name("dev.opendx.ezdiff.toggleDisplayMode")
    static let copyDiff = Notification.Name("dev.opendx.ezdiff.copyDiff")
    static let exportDiff = Notification.Name("dev.opendx.ezdiff.exportDiff")
    static let toggleIgnoreWhitespace = Notification.Name("dev.opendx.ezdiff.toggleIgnoreWhitespace")
}

@main
struct ezdiffApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button("Open Left File...") {
                    NotificationCenter.default.post(name: .openLeftFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Right File...") {
                    NotificationCenter.default.post(name: .openRightFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandGroup(after: .toolbar) {
                Button("Next Hunk") {
                    NotificationCenter.default.post(name: .navigateNextHunk, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .command)

                Button("Previous Hunk") {
                    NotificationCenter.default.post(name: .navigatePrevHunk, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .command)

                Divider()

                Button("Toggle Side-by-Side / Unified") {
                    NotificationCenter.default.post(name: .toggleDisplayMode, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)

                Divider()

                Button("Copy Diff") {
                    NotificationCenter.default.post(name: .copyDiff, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Export Diff...") {
                    NotificationCenter.default.post(name: .exportDiff, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Toggle Ignore Whitespace") {
                    NotificationCenter.default.post(name: .toggleIgnoreWhitespace, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command, .option])
            }
        }
    }
}
