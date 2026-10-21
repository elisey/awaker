// Renders the app icon. Usage:
//   swift Support/make-icon.swift preview <dir>   # every variant at 512 px, for picking one
//   swift Support/make-icon.swift icns <variant> <out.iconset-dir>
import AppKit

let canvas: CGFloat = 1024
// Apple's icon grid: the shape is 824 pt centered on a 1024 pt canvas.
let shapeRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let shapeRadius: CGFloat = 186

struct Palette {
    let top: NSColor
    let bottom: NSColor
    let cup: NSColor
    let cupShade: NSColor
    let steam: NSColor
}

func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}

func background(_ p: Palette) {
    let path = NSBezierPath(roundedRect: shapeRect, xRadius: shapeRadius, yRadius: shapeRadius)
    NSGradient(starting: p.top, ending: p.bottom)!.draw(in: path, angle: -90)
    // Soft inner highlight along the top edge, like the system icons.
    NSGraphicsContext.current!.saveGraphicsState()
    path.addClip()
    let glow = NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: .clear)!
    glow.draw(in: CGRect(x: 100, y: 924 - 260, width: 824, height: 260), angle: 90)
    NSGraphicsContext.current!.restoreGraphicsState()
}

/// Cup body with a handle on the right and a saucer below; `rect` is the body.
func cup(body rect: CGRect, p: Palette, saucer: Bool) {
    let ctx = NSGraphicsContext.current!.cgContext
    if saucer {
        let s = CGRect(x: rect.midX - rect.width * 0.85, y: rect.minY - 50, width: rect.width * 1.7, height: 110)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 40, color: NSColor.black.withAlphaComponent(0.3).cgColor)
        p.cup.setFill()
        NSBezierPath(ovalIn: s).fill()
        ctx.restoreGState()
        p.cupShade.setFill()
        NSBezierPath(ovalIn: s.insetBy(dx: s.width * 0.3, dy: s.height * 0.28)).fill()
    }
    // Handle: a thick ring, the body drawn on top hides its inner half.
    let hr = rect.height * 0.28
    let handle = NSBezierPath(ovalIn: CGRect(x: rect.maxX - hr * 0.6, y: rect.midY - hr, width: 2 * hr, height: 2 * hr))
    handle.lineWidth = hr * 0.55
    p.cup.setStroke()
    handle.stroke()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 48, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    p.cup.setFill()
    NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.18, yRadius: rect.width * 0.18).fill()
    ctx.restoreGState()
    // Rim: an ellipse that reads as the open top, with the coffee inside.
    let rim = CGRect(x: rect.minX, y: rect.maxY - rect.width * 0.11, width: rect.width, height: rect.width * 0.22)
    p.cupShade.setFill()
    NSBezierPath(ovalIn: rim).fill()
    p.bottom.setFill()
    NSBezierPath(ovalIn: rim.insetBy(dx: rect.width * 0.07, dy: rect.width * 0.035)).fill()
}

/// Three rising wisps above `x` center, each a gentle S-curve.
func steam(centerX: CGFloat, baseY: CGFloat, height: CGFloat, color: NSColor) {
    for (i, dx) in [-1.0, 0.0, 1.0].enumerated() {
        let x = centerX + CGFloat(dx) * height * 0.42
        let phase: CGFloat = i == 1 ? 1 : -1
        let h = i == 1 ? height : height * 0.78
        let path = NSBezierPath()
        path.move(to: CGPoint(x: x, y: baseY))
        path.curve(
            to: CGPoint(x: x, y: baseY + h),
            controlPoint1: CGPoint(x: x + phase * h * 0.55, y: baseY + h * 0.3),
            controlPoint2: CGPoint(x: x - phase * h * 0.55, y: baseY + h * 0.7)
        )
        path.lineWidth = height * 0.17
        path.lineCapStyle = .round
        color.withAlphaComponent(i == 1 ? 0.95 : 0.7).setStroke()
        path.stroke()
    }
}

// MARK: - Variants

let variants: [(name: String, draw: () -> Void)] = [
    ("cup", {
        // A steaming cup on its saucer: the "awake" state the app exists for.
        let p = Palette(top: rgb(232, 132, 68), bottom: rgb(150, 64, 34), cup: rgb(252, 247, 240), cupShade: rgb(222, 206, 192), steam: .white)
        background(p)
        cup(body: CGRect(x: 322, y: 280, width: 330, height: 300), p: p, saucer: true)
        steam(centerX: 487, baseY: 640, height: 190, color: p.steam)
    }),
    ("mug", {
        // The tall mug of the "display stays on" state, no saucer.
        let p = Palette(top: rgb(52, 92, 140), bottom: rgb(22, 40, 70), cup: rgb(240, 244, 250), cupShade: rgb(196, 206, 222), steam: rgb(210, 226, 250))
        background(p)
        cup(body: CGRect(x: 340, y: 230, width: 300, height: 400), p: p, saucer: false)
        steam(centerX: 490, baseY: 690, height: 170, color: p.steam)
    }),
    ("night", {
        // Same cup on a dark ground, for those who read "awake" as "late".
        let p = Palette(top: rgb(46, 54, 84), bottom: rgb(22, 26, 44), cup: rgb(255, 196, 87), cupShade: rgb(214, 158, 60), steam: rgb(255, 222, 160))
        background(p)
        cup(body: CGRect(x: 322, y: 280, width: 330, height: 300), p: p, saucer: true)
        steam(centerX: 487, baseY: 640, height: 190, color: p.steam)
    }),
]

// MARK: - Output

func render(_ draw: () -> Void, size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.cgContext.scaleBy(x: CGFloat(size) / canvas, y: CGFloat(size) / canvas)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let args = CommandLine.arguments
switch args.dropFirst().first {
case "preview":
    let dir = URL(fileURLWithPath: args[2])
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for v in variants {
        try! render(v.draw, size: 512).write(to: dir.appendingPathComponent("\(v.name).png"))
    }
case "icns":
    guard let v = variants.first(where: { $0.name == args[2] }) else {
        FileHandle.standardError.write("unknown variant \(args[2]); have: \(variants.map(\.name))\n".data(using: .utf8)!)
        exit(1)
    }
    let dir = URL(fileURLWithPath: args[3])
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for base in [16, 32, 128, 256, 512] {
        try! render(v.draw, size: base).write(to: dir.appendingPathComponent("icon_\(base)x\(base).png"))
        try! render(v.draw, size: base * 2).write(to: dir.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
    }
default:
    FileHandle.standardError.write("usage: make-icon.swift preview <dir> | icns <variant> <iconset-dir>\n".data(using: .utf8)!)
    exit(2)
}
