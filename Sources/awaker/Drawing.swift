import AppKit

func drawCentered(_ text: String, in rect: NSRect, font: NSFont, color: NSColor) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    NSAttributedString(string: text, attributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style,
    ]).draw(in: rect)
}

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
