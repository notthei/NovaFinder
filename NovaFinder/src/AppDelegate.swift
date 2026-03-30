import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager!
    private var windowController: SearchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager = HotkeyManager { [weak self] in
            DispatchQueue.main.async {
                self?.toggleSearch()
            }
        }
        hotkeyManager.register()
    }

    private func toggleSearch() {
        if let wc = windowController, wc.isVisible {
            wc.hide()
        } else {
            if windowController == nil {
                windowController = SearchWindowController()
            }
            windowController?.show()
        }
    }
}
