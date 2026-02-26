# ScreenWake

A minimal macOS menu bar app that starts the screensaver with a single click.

![Moon icon in menu bar](screenshot.png)

---

## Features

- 🌙 **One-click screensaver** — left-click the moon icon to activate instantly
- 🔒 **Auto-locks** — pairs with macOS password-on-wake setting
- 🖱 **Right-click menu** — Start Screensaver or Quit
- 🪶 **Tiny footprint** — single Swift file, ~50KB, no dependencies
- 🔁 **Launches at login** — always in your menu bar

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 14.0 Sonoma+ |
| Xcode | 15+ |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Any |

```bash
brew install xcodegen
```

---

## Build & Install

```bash
git clone https://github.com/rdreilly58/screenwake
cd screenwake

# Generate Xcode project
xcodegen generate

# Build Release
xcodebuild \
  -project ScreenWake.xcodeproj \
  -scheme ScreenWake \
  -configuration Release \
  -derivedDataPath .build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  build

# Install to /Applications
cp -R .build/Build/Products/Release/ScreenWake.app /Applications/

# Launch
open /Applications/ScreenWake.app
```

---

## Lock on Wake

To require a password immediately when the screensaver is dismissed:

```bash
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
```

To set the screensaver to start automatically after 2 minutes idle:

```bash
defaults write com.apple.screensaver idleTime -int 120
```

---

## Project Structure

```
screenwake/
├── project.yml                  # XcodeGen source of truth
├── ScreenWake.xcodeproj/        # Generated — do not edit manually
└── ScreenWake/
    ├── ScreenWakeApp.swift      # Entire app — AppDelegate + NSStatusItem
    ├── Info.plist               # LSUIElement = true (menu bar only)
    └── ScreenWake.entitlements  # Sandbox disabled
```

### How it works

`ScreenWakeApp.swift` sets up an `NSStatusItem` with a `moon.fill` SF Symbol. Left-click launches `ScreenSaverEngine.app` via `Process`. Right-click shows an `NSMenu` with Quit. That's it — the whole app is one file.

```
Left click
    └── open -a ScreenSaverEngine
            └── macOS screensaver activates
                    └── password required on wake (system setting)
```

---

## Auto-launch at Login

Add to login items via System Settings → General → Login Items, or via Terminal:

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ScreenWake.app", hidden:false}'
```

---

## License

MIT
