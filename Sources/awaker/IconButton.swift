import AppKit

/// The ✕ and display buttons of the popover: a glyph drawn in code, highlighted on hover.
final class IconButton: NSButton {
    enum Glyph { case close, display }

    private let glyph: Glyph
    private var hovering = false

    /// Switched on: the display button while the display is kept on.
    var isOn = false {
        didSet { if isOn != oldValue { needsDisplay = true } }
    }

    override var isEnabled: Bool {
        didSet {
            alphaValue = isEnabled ? 1 : Theme.Metrics.disabledOpacity
            if !isEnabled { hovering = false }
            needsDisplay = true
        }
    }

    init(glyph: Glyph, label: String, target: AnyObject?, action: Selector) {
        self.glyph = glyph
        let side = Theme.Metrics.iconButton
        super.init(frame: NSRect(x: 0, y: 0, width: side, height: side))
        self.target = target
        self.action = action
        isBordered = false
        title = ""
        focusRingType = .none
        setAccessibilityLabel(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else { return }
        hovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        needsDisplay = true
    }

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

    override func draw(_ dirtyRect: NSRect) {
        let radius = Theme.Metrics.iconRadius
        let active = isEnabled && (hovering || isHighlighted)
        if isOn {
            Theme.yolk.setFill()
            NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
        } else if active {
            Theme.paperDeep.setFill()
            NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
        }
        if focused {
            let ring = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: radius - 1, yRadius: radius - 1)
            ring.lineWidth = 2
            Theme.ink.setStroke()
            ring.stroke()
        }
        let color = isOn ? Theme.coal : active || focused ? Theme.ink : Theme.inkFaint
        // Glyphs are drawn on the SVG's 12×12 grid, centered in the button.
        let origin = NSPoint(x: bounds.midX - 6, y: bounds.midY - 6)
        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: origin.x + x, y: origin.y + y) }

        color.set()
        let path = NSBezierPath()
        path.lineCapStyle = .round
        switch glyph {
        case .close:
            path.lineWidth = 2.2
            path.move(to: point(2.5, 2.5)); path.line(to: point(9.5, 9.5))
            path.move(to: point(9.5, 2.5)); path.line(to: point(2.5, 9.5))
            path.stroke()
        case .display:
            let screen = NSBezierPath(roundedRect: NSRect(origin: point(1, 1.5), size: NSSize(width: 10, height: 7)),
                                      xRadius: 1.5, yRadius: 1.5)
            screen.lineWidth = 2
            screen.stroke()
            path.lineWidth = 2
            path.move(to: point(4, 11)); path.line(to: point(8, 11))
            path.stroke()
        }
    }
}
