import Testing
@testable import OxxCore

@Suite("Path behavior")
struct PathTests {
    @Test("installed service lives outside the SwiftPM build directory")
    func installedServicePathIsStable() {
        #expect(OxxPaths.installedServiceURL.path.contains("Applications/oxx-service.app/Contents/MacOS/oxx-service"))
        #expect(!OxxPaths.installedServiceURL.path.contains(".build"))
    }
}
