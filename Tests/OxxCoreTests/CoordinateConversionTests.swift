import CoreGraphics
import Testing
@testable import OxxCore

@Suite("Coordinate conversion")
struct CoordinateConversionTests {
    @Test("converts CoreGraphics display center to AppKit screen center")
    func convertsDisplayCenter() {
        let display = DisplayInfo(
            id: 1,
            bounds: CGRect(x: 1512, y: 0, width: 1920, height: 1080),
            isMain: false
        )
        let screens = [
            AppKitScreenInfo(frame: CGRect(x: 1512, y: -98, width: 1920, height: 1080))
        ]

        let point = CoordinateConversion.appKitPoint(
            forCoreGraphicsPoint: CGPoint(x: 2472, y: 540),
            display: display,
            screens: screens
        )

        #expect(point == CGPoint(x: 2472, y: 442))
    }

    @Test("returns the original point when no matching screen exists")
    func returnsOriginalPointWithoutMatchingScreen() {
        let display = DisplayInfo(
            id: 1,
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 800),
            isMain: true
        )

        let point = CoordinateConversion.appKitPoint(
            forCoreGraphicsPoint: CGPoint(x: 500, y: 400),
            display: display,
            screens: []
        )

        #expect(point == CGPoint(x: 500, y: 400))
    }
}
