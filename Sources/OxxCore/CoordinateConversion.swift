import CoreGraphics

public struct AppKitScreenInfo: Equatable, Sendable {
    public let displayID: CGDirectDisplayID?
    public let frame: CGRect

    public init(displayID: CGDirectDisplayID? = nil, frame: CGRect) {
        self.displayID = displayID
        self.frame = frame
    }
}

public enum CoordinateConversion {
    public static func appKitPoint(
        forCoreGraphicsPoint point: CGPoint,
        display: DisplayInfo,
        screens: [AppKitScreenInfo]
    ) -> CGPoint {
        let matchingScreen = screens.first { screen in
            screen.displayID == display.id
        } ?? screens.first { screen in
            abs(screen.frame.minX - display.bounds.minX) < 1 &&
                abs(screen.frame.width - display.bounds.width) < 1 &&
                abs(screen.frame.height - display.bounds.height) < 1
        }

        guard let screen = matchingScreen else {
            return point
        }

        let relativeYFromTop = point.y - display.bounds.minY
        return CGPoint(
            x: point.x,
            y: screen.frame.maxY - relativeYFromTop
        )
    }
}
