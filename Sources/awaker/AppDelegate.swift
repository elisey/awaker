import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let popoverWidth: CGFloat = 150
    static let popoverHeight: CGFloat = 146
    static let lockSize: CGFloat = 22

    private let keeper = Keeper()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var awakeView: AwakeView!
    private var lockButton: NSButton!
    private var tickTimer: Timer?
    private var iconStatus: AwakeStatus?
    private var shownStatus: AwakeStatus?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The three status glyphs differ in width; a variable-length item would shift
        // on every state change and drag the anchored popover along with it.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
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
        let w = Self.popoverWidth, h = Self.popoverHeight
        let container = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))

        awakeView = AwakeView(frame: NSRect(x: 0, y: 0, width: w, height: h), keeper: keeper)
        awakeView.onToggle = { [weak self] in self?.toggleAwake() }
        container.addSubview(awakeView)

        lockButton = NSButton(image: NSImage(), target: self, action: #selector(toggleLock(_:)))
        lockButton.isBordered = false
        lockButton.frame = NSRect(x: w - Self.lockSize - 6, y: 6, width: Self.lockSize, height: Self.lockSize)
        lockButton.toolTip = "Keep the display on"
        container.addSubview(lockButton)

        let quit = NSButton(image: symbolImage("xmark")!, target: self, action: #selector(quit(_:)))
        quit.isBordered = false
        quit.frame = NSRect(x: 6, y: h - 28, width: 22, height: 22)
        container.addSubview(quit)

        let controller = NSViewController()
        controller.view = container
        popover = NSPopover()
        popover.contentViewController = controller
        popover.contentSize = NSSize(width: w, height: h)
        popover.behavior = .transient
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
    }

    private func toggleAwake() {
        keeper.toggle()
        refresh()
    }

    @objc private func toggleLock(_ sender: Any?) {
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
        shownStatus = keeper.status
        setIcon(keeper.status)
        awakeView.refresh()
        let locked = keeper.displayLock
        lockButton.image = symbolImage(locked ? "lock.display" : "lock.open.display", pointSize: 13)
        lockButton.isEnabled = keeper.awake
        lockButton.contentTintColor = locked ? .systemBlue : .secondaryLabelColor
    }

    private func setIcon(_ status: AwakeStatus) {
        guard iconStatus != status else { return }
        iconStatus = status
        statusItem.button?.image = statusImage(status.symbol)
    }
}
