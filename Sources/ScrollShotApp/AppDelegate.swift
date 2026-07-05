import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let globalHotKeyManager = GlobalHotKeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        globalHotKeyManager.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalHotKeyManager.unregister()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
