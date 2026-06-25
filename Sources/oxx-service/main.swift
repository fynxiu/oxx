import AppKit
import CoreGraphics
import Foundation
import OxxCore

struct OxxServiceMain {
    static func main() {
        setbuf(stdout, nil)
        setbuf(stderr, nil)

        if CommandLine.arguments.contains("--check-accessibility") {
            if AccessibilityPermissions.isTrusted(prompt: false) {
                print("Accessibility permission for oxx-service: granted")
                Foundation.exit(0)
            }
            print("Accessibility permission for oxx-service: missing")
            print(AccessibilityPermissions.guidance)
            Foundation.exit(1)
        }

        let service = MiddleClickCycleService()
        service.run()
    }
}

OxxServiceMain.main()

final class MiddleClickCycleService {
    private var eventTap: CFMachPort?
    private var didLogSingleDisplay = false
    private var didLogMissingAccessibility = false
    private let cueOverlay = CursorCueOverlay()

    func run() {
        print("oxx-service starting")
        print("AX trusted preflight: \(AccessibilityPermissions.isTrusted(prompt: false))")

        while !installEventTap() {
            if !didLogMissingAccessibility {
                fputs("Could not create CGEvent tap. \(AccessibilityPermissions.guidance)\n", stderr)
                fputs("Installed service path: \(CommandLine.arguments[0])\n", stderr)
                didLogMissingAccessibility = true
            }
            Thread.sleep(forTimeInterval: 10)
        }

        print("oxx-service listening for middle-click display cycling")
        RunLoop.main.run()
    }

    private func installEventTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let service = Unmanaged<MiddleClickCycleService>
                .fromOpaque(userInfo)
                .takeUnretainedValue()
            return service.handle(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func handle(proxy _: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .otherMouseDown else {
            return Unmanaged.passUnretained(event)
        }

        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        guard buttonNumber == 2 else {
            return Unmanaged.passUnretained(event)
        }

        let config = (try? ConfigStore.loadOrCreateDefault()) ?? .default
        if config.trigger == .middleClick, config.action == .cycleNextDisplay {
            cycleOnce()
        }

        if config.consumeTrigger {
            return nil
        }
        return Unmanaged.passUnretained(event)
    }

    private func cycleOnce() {
        do {
            let config = (try? ConfigStore.loadOrCreateDefault()) ?? .default
            let target = try DisplayRuntime.cycleToNextDisplay()
            didLogSingleDisplay = false
            DispatchQueue.main.async { [cueOverlay] in
                cueOverlay.show(at: target.center, display: target, config: config.visualCue)
            }
            print("Moved cursor to display id=\(target.id) center=(x:\(target.center.x), y:\(target.center.y))")
        } catch DisplayRuntimeError.noNextDisplay {
            if !didLogSingleDisplay {
                print("Only one active display found; middle-click cycle is idle.")
                didLogSingleDisplay = true
            }
        } catch {
            fputs("error: \(error)\n", stderr)
        }
    }
}
