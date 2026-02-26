# ScreenWake

A minimal macOS menu bar app that locks your screen with a single click — screensaver first, then password required.

![Moon icon in menu bar](screenshot.png)

---

## Features

- 🌙 **One-click lock** — left-click the moon icon to start the screensaver and lock instantly
- 🔒 **True lock** — uses `SACLockScreenImmediate` (login.framework) for a real password-protected lock
- 🖱 **Right-click menu** — Lock Screen or Quit
- 🪶 **Tiny footprint** — single Swift file, ~50KB, no dependencies
- 🔁 **Launches at login** — always in your menu bar

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 15.0 Sequoia+ (tested on macOS 26 Tahoe) |
| Xcode | 16+ |
| Apple Developer signing identity | Required |

---

## Build & Install

```bash
git clone https://github.com/rdreilly58/screenwake
cd screenwake

# Build Release
xcodebuild \
  -project ScreenWake.xcodeproj \
  -scheme ScreenWake \
  -configuration Release \
  -derivedDataPath .build \
  build

# Sign (required — SACLockScreenImmediate won't lock without a valid signature)
codesign --force --deep --sign "Apple Development: Your Name (TEAMID)" \
  .build/Build/Products/Release/ScreenWake.app

# Install to /Applications
rm -rf /Applications/ScreenWake.app
cp -R .build/Build/Products/Release/ScreenWake.app /Applications/
codesign --force --deep --sign "Apple Development: Your Name (TEAMID)" \
  /Applications/ScreenWake.app

# Launch
open /Applications/ScreenWake.app
```

> **Note:** Code signing is required. Without it, `SACLockScreenImmediate` starts the
> screensaver but does not engage the password lock. This was confirmed on macOS 26 (Tahoe).

---

## Lock on Wake (one-time setup)

To require a password immediately when the screensaver is dismissed:

```bash
defaults -currentHost write com.apple.screensaver askForPassword -int 1
defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 0
```

> **Important:** Use `-currentHost` scope, not the global `defaults write`. The global scope
> does not apply to screensaver password prompts on modern macOS.

To set the screensaver to start automatically after 2 minutes idle:

```bash
defaults -currentHost write com.apple.screensaver idleTime -int 120
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

`ScreenWakeApp.swift` sets up an `NSStatusItem` with a `moon.fill` SF Symbol.

Left-click starts the screensaver via `open -a ScreenSaverEngine`, then 0.5s later calls
`SACLockScreenImmediate` from the private `login.framework` — which engages the true
password lock. Right-click shows an `NSMenu` with Quit.

```
Left click
    ├── open -a ScreenSaverEngine       (visual transition)
    └── 0.5s later: SACLockScreenImmediate()
            └── password required to wake (login.framework, Versions/A/login)
```

> **macOS 26 note:** `dlopen` must use the versioned path
> `.../login.framework/Versions/A/login` — the bare `.../login.framework/login`
> resolves but `dlsym("SACLockScreenImmediate")` fails silently on Tahoe.

---

## Auto-launch at Login

Add to login items via System Settings → General → Login Items, or via Terminal:

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ScreenWake.app", hidden:false}'
```

---

## License

MIT
