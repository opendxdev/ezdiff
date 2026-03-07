import SwiftUI

extension Notification.Name {
    static let openLeftFile = Notification.Name("dev.opendx.ezdiff.openLeftFile")
    static let openRightFile = Notification.Name("dev.opendx.ezdiff.openRightFile")
    static let saveFile = Notification.Name("dev.opendx.ezdiff.saveFile")
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
        }
    }
}
