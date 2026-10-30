// Renders the app icon: an ultra tile with the cream cup and yolk steam. Usage:
//   swift Support/make-icon.swift png <out.png>                  # 1024 px, for comparing with the design
//   swift Support/make-icon.swift icns <variant> <out.iconset-dir>
import AppKit

let canvas: CGFloat = 1024
// Apple's icon grid: the shape is 824 pt centered on a 1024 pt canvas.
let shapeRect = CGRect(x: 100, y: 100, width: 824, height: 824)
// radius-icon: 23% of the tile.
let shapeRadius: CGFloat = 824 * 0.23
// The cup with its steam (120 grid units) is 63% of the tile.
let markScale: CGFloat = 824 * 0.63 / 120

func rgb(_ value: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255, alpha: 1)
}

let ultra = rgb(0x2E4BFF)
let cream = rgb(0xF1EADF)
let yolk = rgb(0xFFC21A)

// MARK: - The mark
// A copy of Mark in Sources/awaker/Drawing.swift: a script cannot import the app's module.
// Paths are built on the 120 grid with y down.

let opticalCenter = CGPoint(x: 53, y: 70)

func body() -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 16, y: 48))
    path.line(to: CGPoint(x: 80, y: 48))
    path.appendArc(withCenter: CGPoint(x: 80, y: 52), radius: 4, startAngle: 270, endAngle: 360)
    path.line(to: CGPoint(x: 84, y: 94))
    path.appendArc(withCenter: CGPoint(x: 58, y: 94), radius: 26, startAngle: 0, endAngle: 90)
    path.line(to: CGPoint(x: 38, y: 120))
    path.appendArc(withCenter: CGPoint(x: 38, y: 94), radius: 26, startAngle: 90, endAngle: 180)
    path.line(to: CGPoint(x: 12, y: 52))
    path.appendArc(withCenter: CGPoint(x: 16, y: 52), radius: 4, startAngle: 180, endAngle: 270)
    path.close()
    return path
}

func handle() -> NSBezierPath {
    let path = NSBezierPath()
    path.appendArc(withCenter: CGPoint(x: 84, y: 80), radius: 17, startAngle: 270, endAngle: 450)
    return path
}

let steamColumns = [
    CGRect(x: 24, y: 10, width: 12, height: 28),
    CGRect(x: 42, y: 0, width: 12, height: 38),
    CGRect(x: 60, y: 10, width: 12, height: 28),
]

/// The canvas is not flipped, so the grid's y axis is mirrored on the way in.
func gridTransform() -> AffineTransform {
    var t = AffineTransform(translationByX: shapeRect.midX, byY: shapeRect.midY)
    t.scale(x: markScale, y: -markScale)
    t.translate(x: -opticalCenter.x, y: -opticalCenter.y)
    return t
}

func drawIcon() {
    ultra.setFill()
    NSBezierPath(roundedRect: shapeRect, xRadius: shapeRadius, yRadius: shapeRadius).fill()

    let transform = gridTransform()
    func placed(_ path: NSBezierPath) -> NSBezierPath {
        path.transform(using: transform)
        return path
    }
    yolk.setFill()
    for column in steamColumns {
        placed(NSBezierPath(roundedRect: column, xRadius: 6, yRadius: 6)).fill()
    }
    cream.set()
    placed(body()).fill()
    let arc = placed(handle())
    arc.lineWidth = 12 * markScale
    arc.stroke()
}

let variants: [(name: String, draw: () -> Void)] = [
    ("ultra", drawIcon),
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
case "png" where args.count == 3:
    try! render(drawIcon, size: Int(canvas)).write(to: URL(fileURLWithPath: args[2]))
case "icns" where args.count == 4:
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
    FileHandle.standardError.write("usage: make-icon.swift png <out.png> | icns <variant> <iconset-dir>\n".data(using: .utf8)!)
    exit(2)
}
