import Testing
@testable import OxxCore

@Suite("Accessibility prompt policy")
struct AccessibilityPromptPolicyTests {
    @Test("prompts only on the first permission check")
    func promptsOnlyOnce() {
        var policy = AccessibilityPromptPolicy()

        #expect(policy.shouldPromptNow() == true)
        #expect(policy.shouldPromptNow() == false)
        #expect(policy.shouldPromptNow() == false)
    }
}
