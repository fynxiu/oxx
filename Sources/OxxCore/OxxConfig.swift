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

public struct OxxConfig: Codable, Equatable, Sendable {
    public var trigger: OxxTrigger
    public var action: OxxAction
    public var ordering: OxxOrdering
    public var consumeTrigger: Bool

    public static let `default` = OxxConfig(
        trigger: .middleClick,
        action: .cycleNextDisplay,
        ordering: .leftToRightTopToBottom,
        consumeTrigger: false
    )

    public init(
        trigger: OxxTrigger,
        action: OxxAction,
        ordering: OxxOrdering,
        consumeTrigger: Bool
    ) {
        self.trigger = trigger
        self.action = action
        self.ordering = ordering
        self.consumeTrigger = consumeTrigger
    }

    private enum CodingKeys: String, CodingKey {
        case trigger
        case action
        case ordering
        case consumeTrigger
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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trigger.rawValue, forKey: .trigger)
        try container.encode(action.rawValue, forKey: .action)
        try container.encode(ordering.rawValue, forKey: .ordering)
        try container.encode(consumeTrigger, forKey: .consumeTrigger)
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
