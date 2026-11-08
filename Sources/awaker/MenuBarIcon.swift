import AppKit

/// The status item: the mark as a 22×22 template image (see docs/redesign/assets/menubar-*.svg).
/// The menu bar picks the real color.
enum MenuBarIcon {
    static let size = NSSize(width: Theme.Metrics.menubarIcon, height: Theme.Metrics.menubarIcon)
    /// Points per grid unit: the BC2 grid × 0.2 is the icon itself, translate(0, 0) scale(0.2).
    /// The mark fills the icon's height, so it is not centered optically.
    static let scale: CGFloat = 0.2
    static let center = NSPoint(x: Mark.opticalCenter.x * scale, y: Mark.opticalCenter.y * scale)
    /// Outline strokes on the grid: thinner than in the popover so the small cup stays open.
    static let outlineWidth: CGFloat = 8.5
    static let outlineHandleWidth: CGFloat = 9

    static func image(for status: AwakeStatus) -> NSImage {
        let image = NSImage(size: size, flipped: true) { _ in
            drawMark(center: center, scale: scale, variant: status.mark, body: .black, steam: .black,
                     outlineWidth: outlineWidth, outlineHandleWidth: outlineHandleWidth)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description(status)
        return image
    }

    static func description(_ status: AwakeStatus) -> String {
        switch status {
        case .asleep: "awaker, sleeping as usual"
        case .awake: "awaker, staying awake"
        case .awakeDisplay: "awaker, staying awake with the display on"
        }
    }
}
