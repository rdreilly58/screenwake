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
        button.image = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: "Start Screensaver")
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
            activateAndLock()
        }
    }

    // MARK: - Screensaver + Lock

    private func activateAndLock() {
        // Start screensaver for the visual
        shell("/usr/bin/open", args: ["-a", "ScreenSaverEngine"])

        // Lock screen via SACLockScreenImmediate (login.framework)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            lockScreenNow()
        }
    }

    // MARK: - Right-click menu

    private func showContextMenu() {
        let menu = NSMenu()
        let startItem = NSMenuItem(title: "Lock Screen", action: #selector(lockFromMenu), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit ScreenWake", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.popUpMenu(menu)
    }

    @objc private func lockFromMenu() { activateAndLock() }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Shell helper

    private func shell(_ path: String, args: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        try? proc.run()
    }
}

// MARK: - Lock via login.framework (SACLockScreenImmediate)

private func lockScreenNow() {
    let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/login", RTLD_LAZY)
    defer { dlclose(handle) }
    guard let sym = dlsym(handle, "SACLockScreenImmediate") else { return }
    let fn = unsafeBitCast(sym, to: (@convention(c) () -> Void).self)
    fn()
}
