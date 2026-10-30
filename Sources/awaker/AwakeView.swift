import AppKit

/// What the popover shows for a given state.
struct PopoverDisplay: Equatable {
    enum WordTone { case faint, ink }
    enum DisplayButton { case disabled, off, on }

    let mark: MarkVariant
    let word: String
    let wordTone: WordTone
    let pill: String
    let pillLook: PillLook
    let displayButton: DisplayButton

    static func make(_ status: AwakeStatus) -> PopoverDisplay {
        switch status {
        case .asleep:
            PopoverDisplay(mark: status.mark, word: "sleepy", wordTone: .faint,
                           pill: "click the cup", pillLook: .outline, displayButton: .disabled)
        case .awake:
            PopoverDisplay(mark: status.mark, word: "awake", wordTone: .ink,
                           pill: "screen may dim", pillLook: .ink, displayButton: .off)
        case .awakeDisplay:
            PopoverDisplay(mark: status.mark, word: "awake", wordTone: .ink,
                           pill: "screen on", pillLook: .yolk, displayButton: .on)
        }
    }
}

/// The round awake button: a circle with the mark inside. Grows on hover, shrinks while pressed.
final class AwakeView: NSView {
    static let hoverScale: CGFloat = 1.04
    static let pressScale: CGFloat = 0.96
    static let scaleDuration: TimeInterval = 0.12
    static let focusGap: CGFloat = 3
    static let focusWidth: CGFloat = 2
    /// Room around the circle for the hover growth and the focus ring.
    static let margin: CGFloat = 8
    /// Steam rises by this many grid units and falls back, one column after another.
    static let steamRise: CGFloat = 4
    static let steamCycle: TimeInterval = 1.6
    static let steamPhaseStep: TimeInterval = 0.2
    static let steamFrameRate: Double = 30

    /// Lift of each steam column, in grid units, `time` seconds into the animation:
    /// a sine from 0 up to `steamRise` and back, each column `steamPhaseStep` behind the previous.
    static func steamLift(at time: TimeInterval, columns: Int) -> [CGFloat] {
        (0..<columns).map { index in
            let t = time - Double(index) * steamPhaseStep
            return steamRise * CGFloat(1 - cos(2 * .pi * t / steamCycle)) / 2
        }
    }

    /// The view's frame in the popover: the circle at its design place plus the margin.
    static var popoverFrame: NSRect {
        let size = Theme.Metrics.buttonSize
        let circle = NSRect(x: (Theme.Metrics.popoverWidth - size) / 2, y: Theme.Metrics.buttonTop,
                            width: size, height: size)
        return circle.insetBy(dx: -margin, dy: -margin)
    }

    var status: AwakeStatus = .asleep {
        didSet {
            guard status != oldValue else { return }
            needsDisplay = true
            updateSteamTimer()
            NSAccessibility.post(element: self, notification: .valueChanged)
        }
    }
    var onToggle: (() -> Void)?
    /// Set while the popover is shown: the steam only moves when someone can see it.
    var animatesSteam = false {
        didSet { if animatesSteam != oldValue { updateSteamTimer() } }
    }

    private var hovering = false
    private var pressed = false
    /// A click that started on the circle is in progress.
    private var tracking = false
    private var scale: CGFloat = 1
    private var scaleFrom: CGFloat = 1
    private var scaleTo: CGFloat = 1
    private var scaleStart = Date.distantPast
    private var scaleTimer: Timer?
    private var steamStart = Date()
    private var steamTimer: Timer?

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private var radius: CGFloat { Theme.Metrics.buttonSize / 2 }

    private var center: NSPoint { NSPoint(x: bounds.midX, y: bounds.midY) }

    private var awake: Bool { status != .asleep }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        let r = radius * scale
        let circle = NSRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        fillColor.setFill()
        NSBezierPath(ovalIn: circle).fill()

        let markHeight = Theme.Metrics.buttonMark * scale
        let markBox = NSRect(x: center.x - markHeight / 2, y: center.y - markHeight / 2,
                             width: markHeight, height: markHeight)
        let display = PopoverDisplay.make(status)
        if awake {
            drawMark(in: markBox, variant: display.mark, body: Theme.onButton, steam: Theme.steamOnButton,
                     steamLift: currentSteamLift)
        } else {
            drawMark(in: markBox, variant: display.mark, body: Theme.ink, steam: Theme.ink)
        }

        if focused {
            let ringRadius = r + Self.focusGap + Self.focusWidth / 2
            let ring = NSBezierPath(ovalIn: NSRect(x: center.x - ringRadius, y: center.y - ringRadius,
                                                   width: 2 * ringRadius, height: 2 * ringRadius))
            ring.lineWidth = Self.focusWidth
            Theme.ink.setStroke()
            ring.stroke()
        }
    }

    private var fillColor: NSColor {
        switch (awake, pressed) {
        case (false, false): Theme.paperDeep
        case (false, true): Theme.hairline
        case (true, false): Theme.button
        case (true, true): Theme.button.blended(withFraction: 0.1, of: .black) ?? Theme.button
        }
    }

    // MARK: Steam animation

    private var currentSteamLift: [CGFloat] {
        guard steamTimer != nil else { return [] }
        let columns = Mark.steamColumns(status.mark).count
        return Self.steamLift(at: Date().timeIntervalSince(steamStart), columns: columns)
    }

    private func updateSteamTimer() {
        let animate = animatesSteam && awake && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if animate, steamTimer == nil {
            steamStart = Date()
            let timer = Timer(timeInterval: 1 / Self.steamFrameRate, repeats: true) { [weak self] _ in
                self?.needsDisplay = true
            }
            RunLoop.main.add(timer, forMode: .common)
            steamTimer = timer
        } else if !animate, let timer = steamTimer {
            timer.invalidate()
            steamTimer = nil
            needsDisplay = true
        }
    }

    // MARK: Scale animation

    private func updateScale() {
        let target = pressed ? Self.pressScale : hovering ? Self.hoverScale : 1
        guard target != scaleTo else { return }
        scaleFrom = scale
        scaleTo = target
        scaleStart = Date()
        guard scaleTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.stepScale() }
        RunLoop.main.add(timer, forMode: .common)
        scaleTimer = timer
    }

    private func stepScale() {
        let t = min(1, Date().timeIntervalSince(scaleStart) / Self.scaleDuration)
        let eased = 1 - (1 - t) * (1 - t)
        scale = scaleFrom + (scaleTo - scaleFrom) * CGFloat(eased)
        needsDisplay = true
        if t >= 1 {
            scaleTimer?.invalidate()
            scaleTimer = nil
        }
    }

    // MARK: Mouse

    private func hitsButton(_ event: NSEvent) -> Bool {
        let p = convert(event.locationInWindow, from: nil)
        let c = center, r = radius
        return (p.x - c.x) * (p.x - c.x) + (p.y - c.y) * (p.y - c.y) <= r * r
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover(hitsButton(event))
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(false)
    }

    private func updateHover(_ over: Bool) {
        if over { NSCursor.pointingHand.set() } else if hovering { NSCursor.arrow.set() }
        guard over != hovering else { return }
        hovering = over
        updateScale()
    }

    override func mouseDown(with event: NSEvent) {
        guard hitsButton(event) else { return }
        tracking = true
        setPressed(true)
    }

    override func mouseDragged(with event: NSEvent) {
        // Like a regular button: dragging off the circle releases it, dragging back presses it again.
        guard tracking else { return }
        let inside = hitsButton(event)
        if inside != pressed { setPressed(inside) }
    }

    override func mouseUp(with event: NSEvent) {
        guard tracking else { return }
        tracking = false
        setPressed(false)
        if hitsButton(event) { onToggle?() }
    }

    private func setPressed(_ value: Bool) {
        guard value != pressed else { return }
        pressed = value
        needsDisplay = true
        updateScale()
    }

    // MARK: Keyboard and focus

    /// Like NSButton: reachable with Tab only when keyboard navigation is on in System Settings.
    override var acceptsFirstResponder: Bool { NSApp.isFullKeyboardAccessEnabled }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        needsDisplay = true
        return super.resignFirstResponder()
    }

    private var focused: Bool {
        window?.firstResponder === self && window?.isKeyWindow == true
    }

    override func keyDown(with event: NSEvent) {
        // Space and Return press the button, as they do for NSButton.
        if event.charactersIgnoringModifiers == " " || event.keyCode == 36 || event.keyCode == 76 {
            onToggle?()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: Accessibility

    override func isAccessibilityElement() -> Bool { true }

    override func accessibilityRole() -> NSAccessibility.Role? { .button }

    override func accessibilityLabel() -> String? {
        awake ? "Let the Mac sleep" : "Stay awake"
    }

    override func accessibilityValue() -> Any? {
        awake ? "on" : "off"
    }

    override func accessibilityFrame() -> NSRect {
        let r = radius
        let circle = NSRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        guard let window else { return .zero }
        return window.convertToScreen(convert(circle, to: nil))
    }

    override func accessibilityPerformPress() -> Bool {
        onToggle?()
        return true
    }
}

/// The state word and the status pill under the button.
final class StatusView: NSView {
    var status: AwakeStatus = .asleep {
        didSet { if status != oldValue { needsDisplay = true } }
    }

    override var isFlipped: Bool { true }

    /// Clicks go through to the popover; the text is not a control.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        let display = PopoverDisplay.make(status)
        let wordColor = display.wordTone == .ink ? Theme.ink : Theme.inkFaint
        drawCentered(Theme.state.string(display.word, color: wordColor),
                     top: Theme.Metrics.stateTop, lineHeight: Theme.Metrics.stateLineHeight, in: bounds)
        drawPill(display.pill, look: display.pillLook, top: Theme.Metrics.pillTop, in: bounds)
    }
}
