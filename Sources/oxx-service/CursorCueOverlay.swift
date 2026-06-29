import AppKit
import CoreGraphics
import OxxCore

@MainActor
final class CursorCueOverlay {
    private var windows: [NSWindow] = []

    func reset() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    func show(at point: CGPoint, display: DisplayInfo, config: VisualCueConfig) {
        guard config.enabled else {
            return
        }

        let diameter = CGFloat(max(config.diameter, 24))
        let duration = TimeInterval(max(config.durationMilliseconds, 100)) / 1000
        let appKitPoint = CoordinateConversion.appKitPoint(
            forCoreGraphicsPoint: point,
            display: display,
            screens: NSScreen.screens.map {
                AppKitScreenInfo(displayID: $0.displayID, frame: $0.frame)
            }
        )
        let origin = CGPoint(x: appKitPoint.x - diameter / 2, y: appKitPoint.y - diameter / 2)
        let frame = CGRect(origin: origin, size: CGSize(width: diameter, height: diameter))

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

        let view = CursorCueView(frame: CGRect(origin: .zero, size: frame.size))
        window.contentView = view
        windows.append(window)
        window.orderFrontRegardless()
        view.animate(duration: duration)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.08) { [weak self, weak window] in
            guard let self, let window else {
                return
            }
            window.orderOut(nil)
            self.windows.removeAll { $0 === window }
        }
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}

final class CursorCueView: NSView {
    private let ringLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        ringLayer.fillColor = NSColor.clear.cgColor
        ringLayer.strokeColor = NSColor.systemTeal.withAlphaComponent(0.95).cgColor
        ringLayer.lineWidth = 4
        ringLayer.shadowColor = NSColor.black.cgColor
        ringLayer.shadowOpacity = 0.18
        ringLayer.shadowRadius = 5
        ringLayer.shadowOffset = .zero
        layer?.addSublayer(ringLayer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        ringLayer.frame = bounds
        ringLayer.path = CGPath(
            ellipseIn: bounds.insetBy(dx: 8, dy: 8),
            transform: nil
        )
    }

    func animate(duration: TimeInterval) {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.62
        scale.toValue = 1.25
        scale.duration = duration
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 1
        opacity.toValue = 0
        opacity.duration = duration
        opacity.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [scale, opacity]
        group.duration = duration
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        ringLayer.add(group, forKey: "cursor-cue")
    }
}
