import AppKit
import Testing
@testable import awaker

private let fontURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Support/Fonts/Archivo.ttf")

@Suite(.serialized) struct PopoverTests {
    @Test func displayForEachStatus() {
        #expect(PopoverDisplay.make(.asleep) == PopoverDisplay(
            mark: .outline, word: "sleepy", wordTone: .faint,
            pill: "click the cup", pillLook: .outline, displayButton: .disabled))
        #expect(PopoverDisplay.make(.awake) == PopoverDisplay(
            mark: .steam2, word: "awake", wordTone: .ink,
            pill: "screen may dim", pillLook: .ink, displayButton: .off))
        #expect(PopoverDisplay.make(.awakeDisplay) == PopoverDisplay(
            mark: .steam3, word: "awake", wordTone: .ink,
            pill: "screen on", pillLook: .yolk, displayButton: .on))
    }

    @Test func pillsFitThePopover() {
        #expect(Theme.registerFonts(url: fontURL))
        for status in [AwakeStatus.asleep, .awake, .awakeDisplay] {
            let width = pillWidth(PopoverDisplay.make(status).pill)
            #expect(width <= Theme.Metrics.pillMaxWidth)
            #expect(width > 2 * Theme.Metrics.pillPadding)
        }
    }

    @Test func awakeButtonSitsAtItsDesignPlace() {
        let frame = AwakeView.popoverFrame.insetBy(dx: AwakeView.margin, dy: AwakeView.margin)
        #expect(frame == NSRect(x: 60, y: 22, width: 88, height: 88))
        #expect(frame.midY == 66)
    }

    @Test func steamColumnsPerVariant() {
        #expect(Mark.steamColumns(.outline).isEmpty)
        #expect(Mark.steamColumns(.steam2) == [
            NSRect(x: 33, y: 10, width: 12, height: 28), NSRect(x: 51, y: 10, width: 12, height: 28),
        ])
        #expect(Mark.steamColumns(.steam3) == [
            NSRect(x: 24, y: 10, width: 12, height: 28),
            NSRect(x: 42, y: 0, width: 12, height: 38),
            NSRect(x: 60, y: 10, width: 12, height: 28),
        ])
    }

    @Test func markShapesMatchTheGrid() {
        let body = Mark.body().bounds
        #expect(abs(body.minX - 12) < 0.01 && abs(body.maxX - 84) < 0.01)
        #expect(abs(body.minY - 48) < 0.01 && abs(body.maxY - 120) < 0.01)
        let outline = Mark.outline().bounds
        #expect(abs(outline.minX - 16.5) < 0.01 && abs(outline.maxX - 79.5) < 0.01)
        #expect(abs(outline.minY - 52.5) < 0.01 && abs(outline.maxY - 115.5) < 0.01)
        // The handle bulges to the right of the body, from y 63 to 97.
        let handle = Mark.handle().bounds
        #expect(abs(handle.minX - 84) < 0.01 && abs(handle.maxX - 101) < 0.01)
        #expect(abs(handle.minY - 63) < 0.01 && abs(handle.maxY - 97) < 0.01)
    }

    @Test func markIsPlacedByItsOpticalCenter() {
        let t = Mark.transform(center: NSPoint(x: 100, y: 50), scale: 0.5)
        #expect(t.transform(Mark.opticalCenter) == NSPoint(x: 100, y: 50))
        #expect(t.transform(NSPoint(x: 63, y: 80)) == NSPoint(x: 105, y: 55))
        // The menu bar grid: translate(2.375, 0.25) scale(0.125) from the SVGs.
        let menubar = Mark.transform(center: NSPoint(x: 9, y: 9), scale: 0.125)
        #expect(menubar.transform(NSPoint(x: 0, y: 0)) == NSPoint(x: 2.375, y: 0.25))
    }

    @Test func iconButtonDimsWhenDisabled() {
        let button = IconButton(glyph: .display, label: "Keep the display on", target: nil, action: #selector(NSObject.description))
        #expect(button.frame.size == NSSize(width: 24, height: 24))
        button.isEnabled = false
        #expect(button.alphaValue == Theme.Metrics.disabledOpacity)
        button.isEnabled = true
        #expect(button.alphaValue == 1)
    }

    @Test func awakeButtonAccessibility() {
        let view = AwakeView(frame: AwakeView.popoverFrame)
        var toggles = 0
        view.onToggle = { toggles += 1 }
        #expect(view.accessibilityRole() == .button)
        #expect(view.accessibilityLabel() == "Stay awake")
        #expect(view.accessibilityValue() as? String == "off")
        view.status = .awake
        #expect(view.accessibilityLabel() == "Let the Mac sleep")
        #expect(view.accessibilityValue() as? String == "on")
        #expect(view.accessibilityPerformPress())
        #expect(toggles == 1)
    }
}

struct SteamAnimationTests {
    @Test func steamRestsAtTheStartOfACycle() {
        #expect(AwakeView.steamLift(at: 0, columns: 1) == [0])
        let lift = AwakeView.steamLift(at: AwakeView.steamCycle, columns: 1)[0]
        #expect(abs(lift) < 0.0001)
    }

    @Test func steamPeaksHalfwayAtFourGridUnits() {
        let lift = AwakeView.steamLift(at: AwakeView.steamCycle / 2, columns: 1)[0]
        #expect(abs(lift - 4) < 0.0001)
        for step in 0...32 {
            let value = AwakeView.steamLift(at: Double(step) * 0.05, columns: 1)[0]
            #expect(value >= 0 && value <= 4.0001)
        }
    }

    @Test func columnsFollowEachOtherByAFifthOfASecond() {
        let time = 0.7
        let lifts = AwakeView.steamLift(at: time, columns: 3)
        #expect(lifts.count == 3)
        for index in 1..<3 {
            let alone = AwakeView.steamLift(at: time - 0.2 * Double(index), columns: 1)[0]
            #expect(abs(lifts[index] - alone) < 0.0001)
        }
        #expect(lifts[0] != lifts[1])
    }
}
