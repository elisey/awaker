import AppKit
import Testing
@testable import awaker

private let assets = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("docs/redesign/assets")

/// Alpha of every pixel of `image` drawn at `pixels`×`pixels`.
private func alphaMask(_ image: NSImage, pixels: Int) -> [UInt8] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.bitmapData!
    return (0..<pixels * pixels).map { data[$0 * 4 + 3] }
}

struct MenuBarIconTests {
    @Test(arguments: [
        (AwakeStatus.asleep, "menubar-sleepy.svg"),
        (.awake, "menubar-awake.svg"),
        (.awakeDisplay, "menubar-display.svg"),
    ])
    func matchesDesignAsset(status: AwakeStatus, file: String) throws {
        let reference = try #require(NSImage(contentsOf: assets.appendingPathComponent(file)))
        let pixels = 72
        let drawn = alphaMask(MenuBarIcon.image(for: status), pixels: pixels)
        let expected = alphaMask(reference, pixels: pixels)
        // Only antialiasing along the edges may differ.
        let mean = meanDifference(drawn, expected)
        #expect(mean < 2, "mean alpha difference \(mean)")
        #expect(expected.contains { $0 > 0 })

        // The comparison is sharp enough to tell the states apart.
        for other in ["menubar-sleepy.svg", "menubar-awake.svg", "menubar-display.svg"] where other != file {
            let otherMask = alphaMask(try #require(NSImage(contentsOf: assets.appendingPathComponent(other))), pixels: pixels)
            #expect(meanDifference(drawn, otherMask) > 5)
        }
    }

    private func meanDifference(_ a: [UInt8], _ b: [UInt8]) -> Double {
        let difference = zip(a, b).map { abs(Int($0) - Int($1)) }
        return Double(difference.reduce(0, +)) / Double(difference.count)
    }

    @Test func iconIsASquareTemplate() {
        for status in [AwakeStatus.asleep, .awake, .awakeDisplay] {
            let image = MenuBarIcon.image(for: status)
            #expect(image.isTemplate)
            #expect(image.size == NSSize(width: 18, height: 18))
        }
    }

    @Test func statesLookDifferent() {
        let masks = [AwakeStatus.asleep, .awake, .awakeDisplay].map { alphaMask(MenuBarIcon.image(for: $0), pixels: 36) }
        #expect(masks[0] != masks[1])
        #expect(masks[1] != masks[2])
    }

    @Test func steamGrowsWithWakefulness() {
        #expect(AwakeStatus.asleep.mark == .outline)
        #expect(AwakeStatus.awake.mark == .steam2)
        #expect(AwakeStatus.awakeDisplay.mark == .steam3)
    }
}
