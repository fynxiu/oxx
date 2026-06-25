import CoreGraphics
import Testing
@testable import OxxCore

@Suite("Display cycle behavior")
struct DisplayCycleTests {
    @Test("sorts displays left-to-right, then top-to-bottom")
    func sortsDisplaysByGlobalBounds() {
        let displays = [
            DisplayInfo(id: 30, bounds: CGRect(x: 0, y: 900, width: 1000, height: 800), isMain: false),
            DisplayInfo(id: 20, bounds: CGRect(x: 1000, y: 0, width: 1600, height: 900), isMain: false),
            DisplayInfo(id: 10, bounds: CGRect(x: 0, y: 0, width: 1000, height: 800), isMain: true)
        ]

        #expect(DisplayCycle.sorted(displays).map(\.id) == [10, 30, 20])
    }

    @Test("detects the display containing the cursor")
    func findsCurrentDisplay() throws {
        let displays = [
            DisplayInfo(id: 1, bounds: CGRect(x: 0, y: 0, width: 1000, height: 800), isMain: true),
            DisplayInfo(id: 2, bounds: CGRect(x: 1000, y: 0, width: 1000, height: 800), isMain: false)
        ]

        let current = try #require(DisplayCycle.currentDisplay(in: displays, cursor: CGPoint(x: 1200, y: 400)))

        #expect(current.id == 2)
    }

    @Test("chooses the next display in sorted order")
    func choosesNextDisplay() throws {
        let displays = [
            DisplayInfo(id: 2, bounds: CGRect(x: 1000, y: 0, width: 1000, height: 800), isMain: false),
            DisplayInfo(id: 1, bounds: CGRect(x: 0, y: 0, width: 1000, height: 800), isMain: true),
            DisplayInfo(id: 3, bounds: CGRect(x: 2000, y: 0, width: 1000, height: 800), isMain: false)
        ]

        let next = try #require(DisplayCycle.nextDisplay(in: displays, cursor: CGPoint(x: 1200, y: 400)))

        #expect(next.id == 3)
    }

    @Test("wraps from the final display to the first display")
    func wrapsToFirstDisplay() throws {
        let displays = [
            DisplayInfo(id: 1, bounds: CGRect(x: 0, y: 0, width: 1000, height: 800), isMain: true),
            DisplayInfo(id: 2, bounds: CGRect(x: 1000, y: 0, width: 1000, height: 800), isMain: false)
        ]

        let next = try #require(DisplayCycle.nextDisplay(in: displays, cursor: CGPoint(x: 1200, y: 400)))

        #expect(next.id == 1)
    }

    @Test("calculates the display center")
    func calculatesDisplayCenter() {
        let display = DisplayInfo(id: 7, bounds: CGRect(x: -1200, y: 100, width: 1200, height: 700), isMain: false)

        #expect(display.center == CGPoint(x: -600, y: 450))
    }
}
