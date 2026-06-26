import AppKit
import CoreGraphics
import Foundation
import OxxCore

final class WindowFocusController {
    func focusWindow(at point: CGPoint, mode: FocusMode) {
        guard mode == .activateApplication,
              let window = FocusTargetResolver.targetWindow(at: point, windows: currentWindows()),
              let app = NSRunningApplication(processIdentifier: window.ownerPID) else {
            return
        }

        app.activate(options: [.activateIgnoringOtherApps])
    }

    private func currentWindows() -> [WindowInfo] {
        guard let rawWindows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { dictionary in
            guard let ownerPID = dictionary[kCGWindowOwnerPID as String] as? pid_t,
                  let layer = dictionary[kCGWindowLayer as String] as? Int,
                  let boundsDictionary = dictionary[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else {
                return nil
            }

            return WindowInfo(ownerPID: ownerPID, layer: layer, bounds: bounds)
        }
    }
}
