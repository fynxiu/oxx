import Testing
@testable import OxxCore

@Suite("Visual cue config")
struct VisualCueTests {
    @Test("default config enables a short ring cue")
    func defaultVisualCue() {
        let cue = OxxConfig.default.visualCue

        #expect(cue.enabled == true)
        #expect(cue.durationMilliseconds == 450)
        #expect(cue.diameter == 96)
    }

    @Test("loads visual cue overrides")
    func loadsVisualCueOverrides() throws {
        let data = """
        {
          "visualCue": {
            "enabled": false,
            "durationMilliseconds": 700,
            "diameter": 140
          }
        }
        """.data(using: .utf8)!

        let config = try OxxConfig.decode(data)

        #expect(config.visualCue.enabled == false)
        #expect(config.visualCue.durationMilliseconds == 700)
        #expect(config.visualCue.diameter == 140)
    }
}
