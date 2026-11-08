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

extension AwakeStatus {
    /// The mark shared by the menu bar and the round button so both tell the same story.
    var mark: MarkVariant {
        switch self {
        case .asleep: .outline
        case .awake: .steam2
        case .awakeDisplay: .steam3
        }
    }
}

/// The mark's geometry on the BC2 grid (y down; the 22 pt menu bar icon is this grid × 0.2),
/// see docs/redesign/assets/awaker-mark.svg.
enum Mark {
    /// The mark is centered on this point, not on its bounding box: the body's weight
    /// sits low, so box-centering looks off.
    static let opticalCenter = NSPoint(x: 51, y: 66)
    /// The frame around the optical center the mark is fitted into (107×113).
    static let opticalHeight: CGFloat = 113
    static let moduleWidth: CGFloat = 11

    /// Body: 75×55, corners 4 at the top and 22.5 at the bottom.
    static func body() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 11.5, y: 50))
        path.line(to: NSPoint(x: 78.5, y: 50))
        path.appendArc(withCenter: NSPoint(x: 78.5, y: 54), radius: 4, startAngle: 270, endAngle: 360)
        path.line(to: NSPoint(x: 82.5, y: 82.5))
        path.appendArc(withCenter: NSPoint(x: 60, y: 82.5), radius: 22.5, startAngle: 0, endAngle: 90)
        path.line(to: NSPoint(x: 30, y: 105))
        path.appendArc(withCenter: NSPoint(x: 30, y: 82.5), radius: 22.5, startAngle: 90, endAngle: 180)
        path.line(to: NSPoint(x: 7.5, y: 54))
        path.appendArc(withCenter: NSPoint(x: 11.5, y: 54), radius: 4, startAngle: 180, endAngle: 270)
        path.close()
        return path
    }

    /// The body inset by `inset`, meant to be stroked: the cup without steam. The top corners
    /// are square, the bottom ones keep the body's arc centers.
    static func outline(inset: CGFloat) -> NSBezierPath {
        let radius = 22.5 - inset
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 7.5 + inset, y: 50 + inset))
        path.line(to: NSPoint(x: 82.5 - inset, y: 50 + inset))
        path.line(to: NSPoint(x: 82.5 - inset, y: 82.5))
        path.appendArc(withCenter: NSPoint(x: 60, y: 82.5), radius: radius, startAngle: 0, endAngle: 90)
        path.line(to: NSPoint(x: 30, y: 105 - inset))
        path.appendArc(withCenter: NSPoint(x: 30, y: 82.5), radius: radius, startAngle: 90, endAngle: 180)
        path.close()
        path.lineJoinStyle = .round
        return path
    }

    /// Handle: a half circle on the right, meant to be stroked; its butt ends hide in the body.
    static func handle() -> NSBezierPath {
        let path = NSBezierPath()
        path.appendArc(withCenter: NSPoint(x: 82.5, y: 73), radius: 16.5, startAngle: 270, endAngle: 90 + 360)
        return path
    }

    /// Steam columns as (x, y, height); every column is 11 wide with round ends, all end at y 42.
    static func steamColumns(_ variant: MarkVariant) -> [NSRect] {
        switch variant {
        case .outline:
            return []
        case .steam2:
            return [NSRect(x: 31, y: 17, width: 11, height: 25), NSRect(x: 48, y: 17, width: 11, height: 25)]
        case .steam3:
            return [
                NSRect(x: 22.5, y: 17, width: 11, height: 25),
                NSRect(x: 39.5, y: 9.5, width: 11, height: 32.5),
                NSRect(x: 56.5, y: 17, width: 11, height: 25),
            ]
        }
    }

    /// Maps the grid into a flipped context: `scale` per grid unit, optical center at `center`.
    static func transform(center: NSPoint, scale: CGFloat) -> AffineTransform {
        var t = AffineTransform(translationByX: center.x, byY: center.y)
        t.scale(scale)
        t.translate(x: -opticalCenter.x, y: -opticalCenter.y)
        return t
    }
}

/// Draws the mark into a flipped context with the optical frame (107×113) fitted into
/// `box`'s height and the optical center on `box`'s center.
func drawMark(
    in box: NSRect,
    variant: MarkVariant,
    body: NSColor,
    steam: NSColor,
    outlineWidth: CGFloat = 10,
    steamLift: [CGFloat] = []
) {
    let scale = box.height / Mark.opticalHeight
    drawMark(center: NSPoint(x: box.midX, y: box.midY), scale: scale, variant: variant,
             body: body, steam: steam, outlineWidth: outlineWidth, steamLift: steamLift)
}

/// Draws the mark into a flipped context, `scale` points per grid unit, optical center at `center`.
/// `handleWidth` is the handle's stroke on the filled variants. On the outline the handle is
/// `outlineHandleWidth`, by default a little thicker than the body's line, which otherwise makes
/// the handle look thinner. `steamLift` raises each steam column by that many grid units.
func drawMark(
    center: NSPoint,
    scale: CGFloat,
    variant: MarkVariant,
    body: NSColor,
    steam: NSColor,
    outlineWidth: CGFloat = 10,
    outlineHandleWidth: CGFloat? = nil,
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
        let outline = placed(Mark.outline(inset: outlineWidth / 2))
        outline.lineWidth = outlineWidth * scale
        outline.stroke()
        handle.lineWidth = (outlineHandleWidth ?? outlineWidth + 0.5) * scale
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
