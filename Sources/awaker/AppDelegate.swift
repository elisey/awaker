import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let keeper = Keeper()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awakeView: AwakeView!
    private var statusView: StatusView!
    private var displayButton: IconButton!
    private var tickTimer: Timer?
    private var iconStatus: AwakeStatus?
    private var shownStatus: AwakeStatus?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Theme.registerFonts()
        // A fixed-width item keeps the anchored popover from moving when the icon changes.
        statusItem = NSStatusBar.system.statusItem(withLength: Theme.Metrics.menubarIcon)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        buildPopover()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keeper.stop()
    }

    private func buildPopover() {
        typealias M = Theme.Metrics
        let w = M.popoverWidth, h = M.popoverHeight
        let container = PopoverContentView(frame: NSRect(x: 0, y: 0, width: w, height: h))

        statusView = StatusView(frame: container.bounds)
        container.addSubview(statusView)

        awakeView = AwakeView(frame: flipped(AwakeView.popoverFrame, in: h))
        awakeView.onToggle = { [weak self] in self?.toggleAwake() }
        container.addSubview(awakeView)

        let quit = IconButton(glyph: .close, label: "Quit awaker", target: self, action: #selector(quit(_:)))
        quit.frame = flipped(NSRect(x: M.iconInset, y: M.iconInset, width: M.iconButton, height: M.iconButton), in: h)
        container.addSubview(quit)

        displayButton = IconButton(glyph: .display, label: "Keep the display on",
                                   target: self, action: #selector(toggleDisplay(_:)))
        displayButton.toolTip = "Keep the display on"
        displayButton.frame = flipped(
            NSRect(x: w - M.iconInset - M.iconButton, y: M.iconInset, width: M.iconButton, height: M.iconButton),
            in: h
        )
        container.addSubview(displayButton)

        let controller = NSViewController()
        controller.view = container
        popover = NSPopover()
        popover.contentViewController = controller
        popover.contentSize = NSSize(width: w, height: h)
        popover.behavior = .transient
        popover.delegate = self
    }

    func popoverDidShow(_ notification: Notification) {
        awakeView.animatesSteam = true
    }

    func popoverDidClose(_ notification: Notification) {
        awakeView.animatesSteam = false
    }

    /// The container is not flipped; layout values are measured from the top, as in the design.
    private func flipped(_ rect: NSRect, in height: CGFloat) -> NSRect {
        NSRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // An accessory app isn't frontmost, so make the popover key to receive clicks.
        NSApp.activate()
        // Nothing is focused until Tab is pressed; otherwise the button opens with a focus ring.
        popover.contentViewController?.view.window?.makeFirstResponder(nil)
    }

    private func toggleAwake() {
        keeper.toggle()
        refresh()
    }

    @objc private func toggleDisplay(_ sender: Any?) {
        keeper.setDisplayLock(!keeper.displayLock)
        refresh()
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func tick() {
        // caffeinate can be killed from outside; keep the UI honest about it.
        if keeper.status != shownStatus { refresh() }
    }

    private func refresh() {
        let status = keeper.status
        shownStatus = status
        setIcon(status)
        awakeView.status = status
        statusView.status = status
        let display = PopoverDisplay.make(status)
        displayButton.isEnabled = display.displayButton != .disabled
        displayButton.isOn = display.displayButton == .on
    }

    private func setIcon(_ status: AwakeStatus) {
        guard iconStatus != status else { return }
        iconStatus = status
        statusItem.button?.image = MenuBarIcon.image(for: status)
    }
}
