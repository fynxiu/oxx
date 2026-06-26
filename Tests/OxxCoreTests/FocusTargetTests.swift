import CoreGraphics
import Testing
@testable import OxxCore

@Suite("Focus target resolution")
struct FocusTargetTests {
    @Test("chooses the first normal window containing the target point")
    func choosesTopContainingWindow() throws {
        let windows = [
            WindowInfo(ownerPID: 100, layer: 1, bounds: CGRect(x: 0, y: 0, width: 500, height: 500)),
            WindowInfo(ownerPID: 200, layer: 0, bounds: CGRect(x: 800, y: 0, width: 500, height: 500)),
            WindowInfo(ownerPID: 300, layer: 0, bounds: CGRect(x: 0, y: 0, width: 500, height: 500))
        ]

        let target = try #require(FocusTargetResolver.targetWindow(at: CGPoint(x: 250, y: 250), windows: windows))

        #expect(target.ownerPID == 300)
    }

    @Test("returns nil when no normal window contains the point")
    func returnsNilWithoutMatchingWindow() {
        let windows = [
            WindowInfo(ownerPID: 100, layer: 1, bounds: CGRect(x: 0, y: 0, width: 500, height: 500)),
            WindowInfo(ownerPID: 200, layer: 0, bounds: CGRect(x: 800, y: 0, width: 500, height: 500))
        ]

        #expect(FocusTargetResolver.targetWindow(at: CGPoint(x: 250, y: 250), windows: windows) == nil)
    }
}
