import Foundation

public enum OxxConfigError: Error, CustomStringConvertible, Equatable {
    case unsupportedTrigger(String)
    case unsupportedAction(String)
    case unsupportedOrdering(String)

    public var description: String {
        switch self {
        case .unsupportedTrigger(let value):
            return "Unsupported trigger '\(value)'. Supported value: middleClick."
        case .unsupportedAction(let value):
            return "Unsupported action '\(value)'. Supported value: cycleNextDisplay."
        case .unsupportedOrdering(let value):
            return "Unsupported ordering '\(value)'. Supported value: leftToRightTopToBottom."
        }
    }
}

public enum OxxTrigger: String, Codable, Equatable, Sendable {
    case middleClick
}

public enum OxxAction: String, Codable, Equatable, Sendable {
    case cycleNextDisplay
}

public enum OxxOrdering: String, Codable, Equatable, Sendable {
    case leftToRightTopToBottom
}

public enum FocusMode: String, Codable, Equatable, Sendable {
    case none
    case activateApplication
}

public struct VisualCueConfig: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var durationMilliseconds: Int
    public var diameter: Int

    public static let `default` = VisualCueConfig(
        enabled: true,
        durationMilliseconds: 450,
        diameter: 96
    )

    public init(enabled: Bool, durationMilliseconds: Int, diameter: Int) {
        self.enabled = enabled
        self.durationMilliseconds = durationMilliseconds
        self.diameter = diameter
    }
}

public struct OxxConfig: Codable, Equatable, Sendable {
    public var trigger: OxxTrigger
    public var action: OxxAction
    public var ordering: OxxOrdering
    public var consumeTrigger: Bool
    public var visualCue: VisualCueConfig
    public var focusMode: FocusMode

    public static let `default` = OxxConfig(
        trigger: .middleClick,
        action: .cycleNextDisplay,
        ordering: .leftToRightTopToBottom,
        consumeTrigger: false,
        visualCue: .default,
        focusMode: .activateApplication
    )

    public init(
        trigger: OxxTrigger,
        action: OxxAction,
        ordering: OxxOrdering,
        consumeTrigger: Bool,
        visualCue: VisualCueConfig,
        focusMode: FocusMode
    ) {
        self.trigger = trigger
        self.action = action
        self.ordering = ordering
        self.consumeTrigger = consumeTrigger
        self.visualCue = visualCue
        self.focusMode = focusMode
    }

    private enum CodingKeys: String, CodingKey {
        case trigger
        case action
        case ordering
        case consumeTrigger
        case visualCue
        case focusMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let triggerRaw = try container.decodeIfPresent(String.self, forKey: .trigger) ?? OxxTrigger.middleClick.rawValue
        guard let trigger = OxxTrigger(rawValue: triggerRaw) else {
            throw OxxConfigError.unsupportedTrigger(triggerRaw)
        }

        let actionRaw = try container.decodeIfPresent(String.self, forKey: .action) ?? OxxAction.cycleNextDisplay.rawValue
        guard let action = OxxAction(rawValue: actionRaw) else {
            throw OxxConfigError.unsupportedAction(actionRaw)
        }

        let orderingRaw = try container.decodeIfPresent(String.self, forKey: .ordering) ?? OxxOrdering.leftToRightTopToBottom.rawValue
        guard let ordering = OxxOrdering(rawValue: orderingRaw) else {
            throw OxxConfigError.unsupportedOrdering(orderingRaw)
        }

        self.trigger = trigger
        self.action = action
        self.ordering = ordering
        self.consumeTrigger = try container.decodeIfPresent(Bool.self, forKey: .consumeTrigger) ?? false
        self.visualCue = try container.decodeIfPresent(VisualCueConfig.self, forKey: .visualCue) ?? .default
        self.focusMode = try container.decodeIfPresent(FocusMode.self, forKey: .focusMode) ?? .activateApplication
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger.rawValue, forKey: .trigger)
        try container.encode(action.rawValue, forKey: .action)
        try container.encode(ordering.rawValue, forKey: .ordering)
        try container.encode(consumeTrigger, forKey: .consumeTrigger)
        try container.encode(visualCue, forKey: .visualCue)
        try container.encode(focusMode.rawValue, forKey: .focusMode)
    }

    public static func decode(_ data: Data) throws -> OxxConfig {
        try JSONDecoder().decode(OxxConfig.self, from: data)
    }

    public func encodedPretty() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
