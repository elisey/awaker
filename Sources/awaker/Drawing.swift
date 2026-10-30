import AppKit

func hex(from color: NSColor) -> String {
    let c = color.usingColorSpace(.sRGB) ?? color
    return String(
        format: "#%02X%02X%02X",
        Int((c.redComponent * 255).rounded()),
        Int((c.greenComponent * 255).rounded()),
        Int((c.blueComponent * 255).rounded())
    )
}

// MARK: The mark

/// The steaming cup. Steam stands for staying awake: none, two columns, three columns.
enum MarkVariant: Equatable {
    case outline, steam2, steam3
}

/// The mark's geometry on its 120 grid (y down), see docs/redesign/assets/awaker-mark.svg.
enum Mark {
    /// The mark is centered on this point, not on its bounding box: the body's weight
    /// sits low and left, so box-centering looks off.
    static let opticalCenter = NSPoint(x: 53, y: 70)
    /// The frame around the optical center the mark is fitted into.
    static let opticalHeight: CGFloat = 140
    static let moduleWidth: CGFloat = 12

    /// Body: 72×72, corners 4 at the top and 26 at the bottom.
    static func body() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 16, y: 48))
        path.line(to: NSPoint(x: 80, y: 48))
        path.appendArc(withCenter: NSPoint(x: 80, y: 52), radius: 4, startAngle: 270, endAngle: 360)
        path.line(to: NSPoint(x: 84, y: 94))
        path.appendArc(withCenter: NSPoint(x: 58, y: 94), radius: 26, startAngle: 0, endAngle: 90)
        path.line(to: NSPoint(x: 38, y: 120))
        path.appendArc(withCenter: NSPoint(x: 38, y: 94), radius: 26, startAngle: 90, endAngle: 180)
        path.line(to: NSPoint(x: 12, y: 52))
        path.appendArc(withCenter: NSPoint(x: 16, y: 52), radius: 4, startAngle: 180, endAngle: 270)
        path.close()
        return path
    }

    /// The body inset by 4.5, meant to be stroked: the cup without steam.
    static func outline() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 16.5, y: 52.5))
        path.line(to: NSPoint(x: 79.5, y: 52.5))
        path.line(to: NSPoint(x: 79.5, y: 94))
        path.appendArc(withCenter: NSPoint(x: 58, y: 94), radius: 21.5, startAngle: 0, endAngle: 90)
        path.line(to: NSPoint(x: 38, y: 115.5))
        path.appendArc(withCenter: NSPoint(x: 38, y: 94), radius: 21.5, startAngle: 90, endAngle: 180)
        path.close()
        path.lineJoinStyle = .round
        return path
    }

    /// Handle: a half circle on the right, meant to be stroked; its butt ends hide in the body.
    static func handle() -> NSBezierPath {
        let path = NSBezierPath()
        path.appendArc(withCenter: NSPoint(x: 84, y: 80), radius: 17, startAngle: 270, endAngle: 90 + 360)
        return path
    }

    /// Steam columns as (x, y, height); every column is 12 wide with round ends.
    static func steamColumns(_ variant: MarkVariant) -> [NSRect] {
        switch variant {
        case .outline:
            return []
        case .steam2:
            return [NSRect(x: 33, y: 10, width: 12, height: 28), NSRect(x: 51, y: 10, width: 12, height: 28)]
        case .steam3:
            return [
                NSRect(x: 24, y: 10, width: 12, height: 28),
                NSRect(x: 42, y: 0, width: 12, height: 38),
                NSRect(x: 60, y: 10, width: 12, height: 28),
            ]
        }
    }

    /// Maps the 120 grid into a flipped context: `scale` per grid unit, optical center at `center`.
    static func transform(center: NSPoint, scale: CGFloat) -> AffineTransform {
        var t = AffineTransform(translationByX: center.x, byY: center.y)
        t.scale(scale)
        t.translate(x: -opticalCenter.x, y: -opticalCenter.y)
        return t
    }
}

/// Draws the mark into a flipped context with the optical frame (108×140) fitted into
/// `box`'s height and the optical center on `box`'s center.
func drawMark(
    in box: NSRect,
    variant: MarkVariant,
    body: NSColor,
    steam: NSColor,
    outlineWidth: CGFloat = 9,
    steamLift: [CGFloat] = []
) {
    let scale = box.height / Mark.opticalHeight
    drawMark(center: NSPoint(x: box.midX, y: box.midY), scale: scale, variant: variant,
             body: body, steam: steam, outlineWidth: outlineWidth, steamLift: steamLift)
}

/// Draws the mark into a flipped context, `scale` points per grid unit, optical center at `center`.
/// `handleWidth` is the handle's stroke on the filled variants; `steamLift` raises each steam
/// column by that many grid units.
func drawMark(
    center: NSPoint,
    scale: CGFloat,
    variant: MarkVariant,
    body: NSColor,
    steam: NSColor,
    outlineWidth: CGFloat = 9,
    handleWidth: CGFloat = Mark.moduleWidth,
    steamLift: [CGFloat] = []
) {
    let transform = Mark.transform(center: center, scale: scale)
    func placed(_ path: NSBezierPath) -> NSBezierPath {
        path.transform(using: transform)
        return path
    }

    steam.setFill()
    for (index, column) in Mark.steamColumns(variant).enumerated() {
        let lift = index < steamLift.count ? steamLift[index] : 0
        let rect = column.offsetBy(dx: 0, dy: -lift)
        let radius = Mark.moduleWidth / 2
        placed(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)).fill()
    }

    let handle = placed(Mark.handle())
    body.set()
    if variant == .outline {
        let outline = placed(Mark.outline())
        outline.lineWidth = outlineWidth * scale
        outline.stroke()
        handle.lineWidth = outlineWidth * scale
    } else {
        placed(Mark.body()).fill()
        handle.lineWidth = handleWidth * scale
    }
    handle.stroke()
}

// MARK: Text

/// Draws one line of styled text centered horizontally in `rect`, with the glyphs centered
/// vertically in a line box of `lineHeight` starting at `top` (CSS line-height semantics).
/// Expects a flipped view.
func drawCentered(_ text: NSAttributedString, top: CGFloat, lineHeight: CGFloat, in rect: NSRect) {
    let size = text.size()
    let font = text.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
    let ascent = font?.ascender ?? size.height
    let descent = -(font?.descender ?? 0)
    let baseline = top + (lineHeight - ascent - descent) / 2 + ascent
    let origin = NSPoint(x: rect.midX - size.width / 2, y: baseline - ascent)
    text.draw(with: NSRect(origin: origin, size: NSSize(width: size.width, height: ascent + descent)),
              options: [.usesLineFragmentOrigin])
}

enum PillLook: Equatable {
    case outline, ink, yolk
}

/// Width of the status pill for `text`: the label plus padding on both sides.
func pillWidth(_ text: String) -> CGFloat {
    let label = Theme.pill.string(text, color: Theme.ink)
    return (label.size().width + 2 * Theme.Metrics.pillPadding).rounded()
}

/// Status pill centered horizontally in `rect`, top edge at `top`. Expects a flipped view.
func drawPill(_ text: String, look: PillLook, top: CGFloat, in rect: NSRect) {
    let textColor: NSColor
    switch look {
    case .outline: textColor = Theme.ink
    case .ink: textColor = Theme.onInk
    case .yolk: textColor = Theme.coal
    }
    let label = Theme.pill.string(text, color: textColor)
    let height = Theme.Metrics.pillHeight
    let width = pillWidth(text)
    let frame = NSRect(x: (rect.midX - width / 2).rounded(), y: top, width: width, height: height)

    switch look {
    case .outline:
        let lineWidth: CGFloat = 1.5
        let inset = frame.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = NSBezierPath(roundedRect: inset, xRadius: inset.height / 2, yRadius: inset.height / 2)
        path.lineWidth = lineWidth
        Theme.ink.setStroke()
        path.stroke()
    case .ink, .yolk:
        (look == .ink ? Theme.ink : Theme.yolk).setFill()
        NSBezierPath(roundedRect: frame, xRadius: height / 2, yRadius: height / 2).fill()
    }
    drawCentered(label, top: top, lineHeight: height, in: frame)
}

// MARK: SF Symbols

func symbolImage(_ name: String, pointSize: CGFloat? = nil) -> NSImage? {
    guard var image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
    if let pointSize {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        image = image.withSymbolConfiguration(config) ?? image
    }
    image.isTemplate = true
    return image
}

/// Symbols come in different heights; the menu bar item would resize with them and
/// the popover anchored to it would jump, so every icon is padded to the same canvas.
func statusImage(_ name: String) -> NSImage? {
    let canvas: CGFloat = 18
    guard let symbol = symbolImage(name, pointSize: 14) else { return nil }
    let image = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
        let s = symbol.size
        symbol.draw(in: NSRect(x: (canvas - s.width) / 2, y: (canvas - s.height) / 2, width: s.width, height: s.height))
        return true
    }
    image.isTemplate = true
    return image
}
