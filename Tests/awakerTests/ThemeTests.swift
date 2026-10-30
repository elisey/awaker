import AppKit
import CoreText
import Testing
@testable import awaker

private let fontURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Support/Fonts/Archivo.ttf")

private func resolved(_ color: NSColor, dark: Bool) -> String {
    var result = ""
    NSAppearance(named: dark ? .darkAqua : .aqua)!.performAsCurrentDrawingAppearance {
        result = hex(from: color)
    }
    return result
}

private func axisValue(_ font: NSFont, _ tag: Int) -> Double? {
    let variation = CTFontCopyVariation(font) as? [Int: Double]
    return variation?[tag]
}

@Suite(.serialized) struct ThemeTests {
    @Test func dynamicColorsFollowAppearance() {
        let expected: [(NSColor, String, String)] = [
            (Theme.paper, "#F1EADF", "#121212"),
            (Theme.paperDeep, "#E6DCCC", "#1F1E1C"),
            (Theme.hairline, "#D6CAB7", "#34322F"),
            (Theme.ink, "#121212", "#F1EADF"),
            (Theme.inkMuted, "#5E574D", "#B5AC9E"),
            (Theme.inkFaint, "#857D71", "#7F786C"),
            (Theme.onInk, "#F1EADF", "#121212"),
        ]
        for (color, light, dark) in expected {
            #expect(resolved(color, dark: false) == light)
            #expect(resolved(color, dark: true) == dark)
        }
    }

    @Test func fixedColorsIgnoreAppearance() {
        let expected: [(NSColor, String)] = [
            (Theme.ultra, "#2E4BFF"), (Theme.button, "#2E4BFF"),
            (Theme.cream, "#F1EADF"), (Theme.onButton, "#F1EADF"),
            (Theme.yolk, "#FFC21A"), (Theme.steamOnButton, "#FFC21A"),
            (Theme.coal, "#121212"),
        ]
        for (color, value) in expected {
            #expect(resolved(color, dark: false) == value)
            #expect(resolved(color, dark: true) == value)
        }
    }

    @Test func metricsAreUnscaledDesignValues() {
        typealias M = Theme.Metrics
        let expected: [(CGFloat, CGFloat)] = [
            (M.popoverWidth, 208), (M.popoverHeight, 208), (M.buttonSize, 88), (M.buttonTop, 22),
            (M.buttonMark, 58), (M.stateTop, 124), (M.stateLineHeight, 36), (M.pillTop, 170),
            (M.pillHeight, 24), (M.pillPadding, 12), (M.pillMaxWidth, 160), (M.iconButton, 24),
            (M.iconInset, 12), (M.iconRadius, 8), (M.menubarIcon, 18), (M.disabledOpacity, 0.4),
        ]
        for (value, design) in expected {
            #expect(value == design)
        }
    }

    @Test func missingFontFileFallsBackToSystemFont() {
        let missing = URL(fileURLWithPath: "/nonexistent/Archivo.ttf")
        #expect(Theme.registerFonts(url: nil) == false)
        #expect(Theme.registerFonts(url: missing) == false)
    }

    @Test func systemWeightMapping() {
        #expect(Theme.systemWeight(900) == .black)
        #expect(Theme.systemWeight(700) == .bold)
        #expect(Theme.systemWeight(400) == .regular)
        #expect(Theme.systemWeight(1200) == .black)
        #expect(Theme.systemWeight(0) == .ultraLight)
    }

    @Test func archivoAppliesWidthAndWeightAxes() throws {
        #expect(Theme.registerFonts(url: fontURL))
        // Registering twice must not count as a failure.
        #expect(Theme.registerFonts(url: fontURL))

        let font = Theme.state.font
        #expect(font.familyName == "Archivo")
        #expect(axisValue(font, 0x7764_7468) == 125)
        #expect(axisValue(font, 0x7767_6874) == 900)

        let sample = "sleepy"
        let wide = NSAttributedString(string: sample, attributes: [.font: font]).size().width
        let narrow = NSAttributedString(string: sample, attributes: [.font: Theme.font(size: 36, weight: 900, width: 62)]).size().width
        #expect(wide > narrow * 1.3)
    }

    @Test func textStylesMatchDesignSystem() {
        #expect(Theme.state.size == 36 && Theme.state.weight == 900 && Theme.state.width == 125)
        #expect(Theme.state.tracking == -0.05 && !Theme.state.uppercase)
        #expect(Theme.pill.size == 11 && Theme.pill.weight == 900 && Theme.pill.width == 125)
        #expect(Theme.pill.tracking == 0.04 && Theme.pill.uppercase)
        #expect(Theme.label.size == 13 && Theme.label.weight == 700 && Theme.label.width == 125)
    }

    @Test func textStyleAppliesTrackingAndCase() {
        let text = Theme.pill.string("screen on", color: Theme.ink)
        #expect(text.string == "SCREEN ON")
        let kern = text.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat
        #expect(kern == Theme.pill.size * 0.04)
        #expect(text.attribute(.kern, at: text.length - 1, effectiveRange: nil) == nil)
        #expect(Theme.state.string("awake", color: Theme.ink).string == "awake")
    }
}
