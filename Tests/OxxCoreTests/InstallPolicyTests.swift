import Testing
@testable import OxxCore

@Suite("Install policy")
struct InstallPolicyTests {
    @Test("default install preserves an existing service app")
    func defaultInstallPreservesExistingServiceApp() {
        #expect(ServiceInstallPolicy.shouldReplaceExistingApp(appExists: true, forceReplace: false) == false)
    }

    @Test("forced install replaces an existing service app")
    func forcedInstallReplacesExistingServiceApp() {
        #expect(ServiceInstallPolicy.shouldReplaceExistingApp(appExists: true, forceReplace: true) == true)
    }

    @Test("default install creates a missing service app")
    func defaultInstallCreatesMissingServiceApp() {
        #expect(ServiceInstallPolicy.shouldReplaceExistingApp(appExists: false, forceReplace: false) == true)
    }
}
