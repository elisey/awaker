import AppKit

/// The status item: the mark as an 18×18 template image (see docs/redesign/assets/menubar-*.svg).
/// The menu bar picks the real color.
enum MenuBarIcon {
    static let size = NSSize(width: Theme.Metrics.menubarIcon, height: Theme.Metrics.menubarIcon)
    /// Grid units per point: translate(2.375, 0.25) scale(0.125) puts the optical center on (9, 9).
    static let scale: CGFloat = 0.125
    /// Stroke widths on the 120 grid: thicker than in the popover so the mark holds at 18 pt.
    static let outlineWidth: CGFloat = 12
    static let handleWidth: CGFloat = 13

    static func image(for status: AwakeStatus) -> NSImage {
        let image = NSImage(size: size, flipped: true) { bounds in
            drawMark(center: NSPoint(x: bounds.midX, y: bounds.midY), scale: scale, variant: status.mark,
                     body: .black, steam: .black, outlineWidth: outlineWidth, handleWidth: handleWidth)
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
