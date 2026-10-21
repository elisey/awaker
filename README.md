# awaker

A macOS menu bar switch that keeps the Mac from sleeping. One click runs
`caffeinate` for as long as you want; a second click lets the Mac sleep again.
Optionally the display is kept on too.

Native Swift / AppKit, no dependencies, macOS 15 or newer.

## Build and install

Needs the Xcode Command Line Tools (`xcode-select --install`); full Xcode is not required.

```sh
make            # builds awaker.app in the repo
make run        # builds and launches it
make install    # copies to ~/Applications (PREFIX=/Applications for system-wide)
make uninstall
```

Launch it from Spotlight or with `open -a awaker`; add it to System Settings →
General → Login Items to start it at login. The bundle is ad-hoc signed; to run
it on another Mac without a Gatekeeper warning you would need a Developer ID and
notarization.

## Usage

Click the menu bar icon to open the panel:

- **the round button** — toggle: keep the Mac awake / let it sleep as usual;
- **🔒 display** (bottom right, enabled only while awake) — also keep the display
  from turning off;
- **✕** — quit.

The menu bar icon shows the current state: a cup and saucer while the Mac sleeps
as usual, a steaming cup while it is kept awake, a mug while the display is kept
on as well.

Under the hood every "awake" session is a single `caffeinate -is` (plus `-d` for the
display) process tied to the app's pid, so quitting or killing the app always
releases the assertion.

## Layout

| File | What it does |
|---|---|
| `Sources/awaker/Keeper.swift` | Owns the `caffeinate` process; start / stop / display flag, state and labels |
| `Sources/awaker/AwakeView.swift` | The round toggle button and its labels |
| `Sources/awaker/Drawing.swift` | Text and SF Symbol helpers, fixed-size status bar icon |
| `Sources/awaker/AppDelegate.swift` | Status item, popover, lock and quit buttons, tick timer |
| `Support/Info.plist` | Bundle metadata; `LSUIElement` keeps the app out of the Dock |
| `Support/make-icon.swift` | Draws the app icon; `make icon` regenerates `Support/awaker.icns` |
