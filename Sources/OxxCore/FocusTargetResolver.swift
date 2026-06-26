import CoreGraphics

public struct WindowInfo: Equatable, Sendable {
    public let ownerPID: pid_t
    public let layer: Int
    public let bounds: CGRect

    public init(ownerPID: pid_t, layer: Int, bounds: CGRect) {
        self.ownerPID = ownerPID
        self.layer = layer
        self.bounds = bounds
    }
}

public enum FocusTargetResolver {
    public static func targetWindow(at point: CGPoint, windows: [WindowInfo]) -> WindowInfo? {
        windows.first { window in
            window.layer == 0 && window.bounds.contains(point)
        }
    }
}
