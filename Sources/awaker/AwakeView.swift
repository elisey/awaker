import AppKit

/// Lets clicks on the glyph land on the round button underneath.
final class PassthroughImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class AwakeView: NSView {
    static let buttonRadius: CGFloat = 22
    static let buttonCenter = NSPoint(x: AppDelegate.popoverWidth / 2, y: 48)
    static let textTop: CGFloat = 78

    let keeper: Keeper
    var onToggle: (() -> Void)?

    private var pressed = false
    private let glyph: PassthroughImageView

    init(frame: NSRect, keeper: Keeper) {
        self.keeper = keeper
        let c = Self.buttonCenter
        glyph = PassthroughImageView(frame: NSRect(x: c.x - 14, y: c.y - 14, width: 28, height: 28))
        super.init(frame: frame)
        addSubview(glyph)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func refresh() {
        glyph.image = symbolImage(keeper.status.symbol, pointSize: 20)
        glyph.contentTintColor = keeper.awake ? .white : .systemBlue
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let c = Self.buttonCenter, r = Self.buttonRadius
        let circle = NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        let blue = NSColor.systemBlue
        if keeper.awake {
            (pressed ? blue.shadow(withLevel: 0.15) ?? blue : blue).setFill()
            circle.fill()
        } else {
            if pressed {
                blue.withAlphaComponent(0.15).setFill()
                circle.fill()
            }
            blue.setStroke()
            circle.lineWidth = 2
            circle.stroke()
        }

        let (main, sub) = keeper.labels
        let top = Self.textTop
        drawCentered(
            main,
            in: NSRect(x: 0, y: top, width: bounds.width, height: 20),
            font: .systemFont(ofSize: 15, weight: .medium),
            color: .labelColor
        )
        drawCentered(
            sub,
            in: NSRect(x: 0, y: top + 22, width: bounds.width, height: 16),
            font: .systemFont(ofSize: 11),
            color: .secondaryLabelColor
        )
    }

    private func hitsButton(_ event: NSEvent) -> Bool {
        let p = convert(event.locationInWindow, from: nil)
        let c = Self.buttonCenter, r = Self.buttonRadius
        return (p.x - c.x) * (p.x - c.x) + (p.y - c.y) * (p.y - c.y) <= r * r
    }

    override func mouseDown(with event: NSEvent) {
        guard hitsButton(event) else { return }
        pressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard pressed else { return }
        pressed = false
        if hitsButton(event) { onToggle?() }
        needsDisplay = true
    }
}
