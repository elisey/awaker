import AppKit
import Testing

private let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// RGBA bytes of the image at `path` drawn at 1024×1024.
private func pixels(_ url: URL) throws -> [UInt8] {
    let image = try #require(NSImage(contentsOf: url))
    let side = 1024
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    return Array(UnsafeBufferPointer(start: rep.bitmapData!, count: side * side * 4))
}

struct AppIconTests {
    @Test func makeIconMatchesDesignAsset() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("awaker-icon-\(UUID()).png")
        defer { try? FileManager.default.removeItem(at: output) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", root.appendingPathComponent("Support/make-icon.swift").path, "png", output.path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)

        let drawn = try pixels(output)
        let expected = try pixels(root.appendingPathComponent("docs/redesign/assets/awaker-app-icon.png"))
        // Only antialiasing along the edges may differ.
        let differing = stride(from: 0, to: drawn.count, by: 4).filter { i in
            (0..<4).contains { abs(Int(drawn[i + $0]) - Int(expected[i + $0])) > 64 }
        }
        #expect(differing.count < 100, "\(differing.count) pixels differ")
    }
}
