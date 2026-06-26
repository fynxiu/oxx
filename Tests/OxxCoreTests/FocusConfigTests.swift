import Testing
@testable import OxxCore

@Suite("Focus config")
struct FocusConfigTests {
    @Test("default config activates the app under the new cursor position")
    func defaultFocusMode() {
        #expect(OxxConfig.default.focusMode == .activateApplication)
    }

    @Test("loads focus mode override")
    func loadsFocusModeOverride() throws {
        let data = #"{"focusMode":"none"}"#.data(using: .utf8)!

        let config = try OxxConfig.decode(data)

        #expect(config.focusMode == .none)
    }
}
