import CoreGraphics

public struct DisplayInfo: Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let bounds: CGRect
    public let isMain: Bool

    public init(id: CGDirectDisplayID, bounds: CGRect, isMain: Bool) {
        self.id = id
        self.bounds = bounds
        self.isMain = isMain
    }

    public var center: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

public enum DisplayCycle {
    public static func sorted(_ displays: [DisplayInfo]) -> [DisplayInfo] {
        displays.sorted { lhs, rhs in
            if abs(lhs.bounds.minX - rhs.bounds.minX) > 0.5 {
                return lhs.bounds.minX < rhs.bounds.minX
            }
            if abs(lhs.bounds.minY - rhs.bounds.minY) > 0.5 {
                return lhs.bounds.minY < rhs.bounds.minY
            }
            return lhs.id < rhs.id
        }
    }

    public static func currentDisplay(in displays: [DisplayInfo], cursor: CGPoint) -> DisplayInfo? {
        displays.first { display in
            display.bounds.insetBy(dx: -0.5, dy: -0.5).contains(cursor)
        }
    }

    public static func nextDisplay(in displays: [DisplayInfo], cursor: CGPoint) -> DisplayInfo? {
        let ordered = sorted(displays)
        guard ordered.count > 1 else {
            return nil
        }

        guard let current = currentDisplay(in: ordered, cursor: cursor),
              let currentIndex = ordered.firstIndex(of: current) else {
            return ordered.first
        }

        return ordered[(currentIndex + 1) % ordered.count]
    }
}
