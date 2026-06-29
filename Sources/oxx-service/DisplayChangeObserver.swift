import AppKit
import CoreGraphics
import Foundation

final class DisplayChangeObserver {
    private let onChange: @Sendable () -> Void

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, context)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersChanged() {
        handleDisplayChange(source: "NSApplication.didChangeScreenParametersNotification")
    }

    fileprivate func handleDisplayChange(source: String) {
        print("Display configuration changed: \(source)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [onChange] in
            _ = NSScreen.screens
            onChange()
        }
    }
}

private let displayReconfigurationCallback: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
    guard let userInfo else {
        return
    }

    let observer = Unmanaged<DisplayChangeObserver>
        .fromOpaque(userInfo)
        .takeUnretainedValue()
    observer.handleDisplayChange(source: "CGDisplayReconfiguration flags=\(flags.rawValue)")
}
