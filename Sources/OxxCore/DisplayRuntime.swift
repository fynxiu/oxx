import CoreGraphics

public enum DisplayRuntimeError: Error, CustomStringConvertible {
    case cannotReadDisplayCount(CGError)
    case cannotReadDisplays(CGError)
    case cannotReadMousePosition
    case displayIndexOutOfRange(Int)
    case noDisplays
    case noNextDisplay

    public var description: String {
        switch self {
        case .cannotReadDisplayCount(let error):
            return "Could not read display count: \(error)"
        case .cannotReadDisplays(let error):
            return "Could not read active displays: \(error)"
        case .cannotReadMousePosition:
            return "Could not read the current mouse position."
        case .displayIndexOutOfRange(let index):
            return "Display index \(index) is out of range."
        case .noDisplays:
            return "No active displays were found."
        case .noNextDisplay:
            return "There is no next display to jump to."
        }
    }
}

public enum DisplayRuntime {
    public static func activeDisplays() throws -> [DisplayInfo] {
        var displayCount: UInt32 = 0
        let countError = CGGetActiveDisplayList(0, nil, &displayCount)
        guard countError == .success else {
            throw DisplayRuntimeError.cannotReadDisplayCount(countError)
        }
        guard displayCount > 0 else {
            return []
        }

        var ids = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        var actualCount: UInt32 = 0
        let listError = ids.withUnsafeMutableBufferPointer { buffer in
            CGGetActiveDisplayList(displayCount, buffer.baseAddress, &actualCount)
        }
        guard listError == .success else {
            throw DisplayRuntimeError.cannotReadDisplays(listError)
        }

        return ids.prefix(Int(actualCount)).map { id in
            DisplayInfo(
                id: id,
                bounds: CGDisplayBounds(id),
                isMain: id == CGMainDisplayID()
            )
        }
        .filter { !$0.bounds.isEmpty }
    }

    public static func orderedDisplays() throws -> [DisplayInfo] {
        DisplayCycle.sorted(try activeDisplays())
    }

    public static func currentMousePosition() throws -> CGPoint {
        guard let event = CGEvent(source: nil) else {
            throw DisplayRuntimeError.cannotReadMousePosition
        }
        return event.location
    }

    @discardableResult
    public static func jumpToDisplay(index: Int) throws -> DisplayInfo {
        let displays = try orderedDisplays()
        guard !displays.isEmpty else {
            throw DisplayRuntimeError.noDisplays
        }
        guard displays.indices.contains(index) else {
            throw DisplayRuntimeError.displayIndexOutOfRange(index)
        }

        let target = displays[index]
        CGWarpMouseCursorPosition(target.center)
        return target
    }

    @discardableResult
    public static func cycleToNextDisplay() throws -> DisplayInfo {
        let displays = try activeDisplays()
        let cursor = try currentMousePosition()
        guard let target = DisplayCycle.nextDisplay(in: displays, cursor: cursor) else {
            throw DisplayRuntimeError.noNextDisplay
        }

        CGWarpMouseCursorPosition(target.center)
        return target
    }
}
