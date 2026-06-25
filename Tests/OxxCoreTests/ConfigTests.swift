import Testing
@testable import OxxCore

@Suite("Config behavior")
struct ConfigTests {
    @Test("default config uses middle-click cycling and passes events through")
    func defaultConfig() {
        let config = OxxConfig.default

        #expect(config.trigger == .middleClick)
        #expect(config.action == .cycleNextDisplay)
        #expect(config.ordering == .leftToRightTopToBottom)
        #expect(config.consumeTrigger == false)
    }

    @Test("loads default config from empty JSON")
    func loadsDefaultConfigFromEmptyJSON() throws {
        let data = "{}".data(using: .utf8)!

        let config = try OxxConfig.decode(data)

        #expect(config == .default)
    }

    @Test("rejects unsupported trigger values")
    func rejectsUnsupportedTriggerValues() {
        let data = #"{"trigger":"rightClick"}"#.data(using: .utf8)!

        #expect(throws: OxxConfigError.self) {
            try OxxConfig.decode(data)
        }
    }
}
