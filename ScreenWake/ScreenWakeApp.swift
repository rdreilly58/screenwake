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
        button.image?.isTemplate = true          // adapts to light/dark menu bar
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
            activateScreenSaver()
        }
    }

    // MARK: - Screensaver + Lock

    private func activateScreenSaver() {
        // Start screensaver for the visual
        run("/usr/bin/open", args: ["-a", "ScreenSaverEngine"])

        // Lock session after brief delay — ensures password required on wake
        // regardless of system screensaver password setting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.run(
                "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession",
                args: ["-suspend"]
            )
        }
    }

    private func run(_ path: String, args: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        try? proc.run()
    }

    // MARK: - Right-click menu

    private func showContextMenu() {
        let menu = NSMenu()
        let startItem = NSMenuItem(title: "Start Screensaver", action: #selector(activateScreenSaverMenu), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit ScreenWake", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.popUpMenu(menu)
    }

    @objc private func activateScreenSaverMenu() { activateScreenSaver() }
    @objc private func quit() { NSApp.terminate(nil) }
}
