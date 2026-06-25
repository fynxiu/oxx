import ApplicationServices
import Foundation

public enum AccessibilityPermissions {
    public static func isTrusted(prompt: Bool = false) -> Bool {
        let key = "AXTrustedCheckOptionPrompt"
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static var settingsURL: String {
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    }

    public static var guidance: String {
        "Grant Accessibility permission in System Settings > Privacy & Security > Accessibility."
    }
}

public struct AccessibilityPromptPolicy: Sendable {
    private var hasPrompted = false

    public init() {}

    public mutating func shouldPromptNow() -> Bool {
        defer { hasPrompted = true }
        return !hasPrompted
    }
}
