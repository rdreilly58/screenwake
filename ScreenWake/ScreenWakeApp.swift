import SwiftUI
import AppKit

@main
struct ScreenWakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — menu bar only
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Lock Screen")
        button.image?.isTemplate = true
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    // MARK: - Click handler

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            lockScreen()
        }
    }

    // MARK: - Lock

    private func lockScreen() {
        // Start screensaver first for the visual transition
        shell("/usr/bin/open", args: ["-a", "ScreenSaverEngine"])
        // Then lock after a short delay so the screensaver is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            lockScreenNow()
        }
    }

    // MARK: - Shell helper

    private func shell(_ path: String, args: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        try? proc.run()
    }

    // MARK: - Right-click menu

    private func showContextMenu() {
        let menu = NSMenu()
        let lockItem = NSMenuItem(title: "Lock Screen", action: #selector(lockFromMenu), keyEquivalent: "")
        lockItem.target = self
        menu.addItem(lockItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit ScreenWake", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.popUpMenu(menu)
    }

    @objc private func lockFromMenu() { lockScreen() }
    @objc private func quit() { NSApp.terminate(nil) }
}

// MARK: - Lock via SACLockScreenImmediate (login.framework)

private func lockScreenNow() {
    let handle = dlopen(
        "/System/Library/PrivateFrameworks/login.framework/Versions/A/login",
        RTLD_LAZY
    )
    defer { dlclose(handle) }
    guard let sym = dlsym(handle, "SACLockScreenImmediate") else { return }
    let fn = unsafeBitCast(sym, to: (@convention(c) () -> Void).self)
    fn()
}
