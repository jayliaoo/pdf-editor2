import SwiftUI
import PDFKit

@main
struct PDFEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environment(\.openURL, OpenURLAction { url in
                    // 处理 URL 打开
                    return .handled
                })
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button("Export Current Page...") {
                    NotificationCenter.default.post(name: .exportCurrentPage, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Extract Images...") {
                    NotificationCenter.default.post(name: .extractImages, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            CommandMenu("Pages") {
                Button("Rotate Clockwise") {
                    NotificationCenter.default.post(name: .rotateClockwise, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Rotate Counterclockwise") {
                    NotificationCenter.default.post(name: .rotateCounterclockwise, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift, .option])

                Divider()

                Button("Delete Page") {
                    NotificationCenter.default.post(name: .deleteCurrentPage, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
    }
}
