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
make test       # runs the tests
make install    # copies to ~/Applications (PREFIX=/Applications for system-wide)
make uninstall
```

Launch it from Spotlight or with `open -a awaker`; add it to System Settings →
General → Login Items to start it at login. The bundle is ad-hoc signed; to run
it on another Mac without a Gatekeeper warning you would need a Developer ID and
notarization.

## Usage

Click the menu bar icon to open the panel:

- **the round button with the cup** — toggle: keep the Mac awake / let it sleep as usual;
- **display** (top right, enabled only while awake) — also keep the display
  from turning off; it turns yellow while it is on;
- **✕** (top left) — quit.

The steam of the cup tells the state, in the menu bar and in the panel alike:
an empty cup outline while the Mac sleeps as usual, two columns of steam while
it is kept awake, three while the display is kept on as well.

Under the hood every "awake" session is a single `caffeinate -is` (plus `-d` for the
display) process tied to the app's pid, so quitting or killing the app always
releases the assertion.

## Design

Colors, sizes and type styles come from the awaker design system
(`docs/redesign/tokens.json`, brand book in `docs/redesign/BRAND.md`) and live
in `Sources/awaker/Theme.swift`; every color has a light and a dark value and
follows the system appearance. Sizes are the design's final points, nothing is
scaled.

The interface is set in [Archivo](https://github.com/Omnibus-Type/Archivo), a
variable font with width and weight axes, used at width 125. It is licensed under
the SIL Open Font License 1.1: the font and its license are in `Support/Fonts`
(`Archivo.ttf`, `OFL.txt`), `make` copies them into the bundle's
`Resources/Fonts`, and the app registers the font at launch. Without it (for
example `swift run` outside the bundle) the app falls back to the system font.

The mark — a squat cup with tall steam (variant BC2 in the design system) — is
drawn in code from one geometry (`Mark` and `drawMark` in
`Sources/awaker/Drawing.swift`) for the round button and the menu bar. The menu
bar icon is a 22 pt template image that fills the height of the bar. The app icon is drawn by `Support/make-icon.swift`, which
carries its own copy of that geometry; `make icon` regenerates
`Support/awaker.icns` from the `ultra` variant.

## Layout

| File | What it does |
|---|---|
| `Sources/awaker/Keeper.swift` | Owns the `caffeinate` process; start / stop / display flag and state |
| `Sources/awaker/Theme.swift` | Design tokens: colors, metrics, Archivo text styles |
| `Sources/awaker/Drawing.swift` | The cup mark, status pill, centered text |
| `Sources/awaker/AwakeView.swift` | The round toggle button, the state word and pill of each state |
| `Sources/awaker/IconButton.swift` | The ✕ and display buttons |
| `Sources/awaker/PopoverBackground.swift` | Solid paper background for the popover, arrow included |
| `Sources/awaker/MenuBarIcon.swift` | Menu bar template icon |
| `Sources/awaker/AppDelegate.swift` | Status item, popover, tick timer |
| `Tests/awakerTests` | Tests for the tokens, fonts, panel states, mark and icons |
| `Support/Info.plist` | Bundle metadata; `LSUIElement` keeps the app out of the Dock |
| `Support/Fonts` | Archivo and its license |
| `Support/make-icon.swift` | Draws the app icon; `make icon` regenerates `Support/awaker.icns` |
