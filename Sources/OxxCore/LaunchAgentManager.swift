import Foundation

public enum LaunchAgentError: Error, CustomStringConvertible {
    case serviceBinaryMissing(URL)
    case commandFailed(String, Int32)

    public var description: String {
        switch self {
        case .serviceBinaryMissing(let url):
            return "oxx-service was not found at \(url.path). Run `swift build --product oxx-service -c release` first."
        case .commandFailed(let command, let status):
            return "`\(command)` failed with exit status \(status)."
        }
    }
}

public enum LaunchAgentManager {
    private static let serviceBundleIdentifier = "dev.fyn.oxx.service"

    public static func plist(servicePath: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(OxxPaths.label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(servicePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>\(OxxPaths.stdoutLogURL.path)</string>
            <key>StandardErrorPath</key>
            <string>\(OxxPaths.stderrLogURL.path)</string>
        </dict>
        </plist>
        """
    }

    @discardableResult
    public static func install(serviceURL: URL, forceReplace: Bool = false) throws -> URL {
        guard FileManager.default.isExecutableFile(atPath: serviceURL.path) else {
            throw LaunchAgentError.serviceBinaryMissing(serviceURL)
        }

        let appExists = FileManager.default.fileExists(atPath: OxxPaths.installedServiceURL.path)
        if ServiceInstallPolicy.shouldReplaceExistingApp(appExists: appExists, forceReplace: forceReplace) {
            try installServiceApp(from: serviceURL)
        }

        try FileManager.default.createDirectory(
            at: OxxPaths.launchAgentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: OxxPaths.logDirectoryURL,
            withIntermediateDirectories: true
        )
        _ = try ConfigStore.loadOrCreateDefault()

        try plist(servicePath: OxxPaths.installedServiceURL.path).write(
            to: OxxPaths.launchAgentURL,
            atomically: true,
            encoding: .utf8
        )

        _ = try? runLaunchctl(["bootout", userDomain(), OxxPaths.launchAgentURL.path])
        try runLaunchctl(["bootstrap", userDomain(), OxxPaths.launchAgentURL.path])
        try runLaunchctl(["enable", "\(userDomain())/\(OxxPaths.label)"])
        try runLaunchctl(["kickstart", "-k", "\(userDomain())/\(OxxPaths.label)"])
        return OxxPaths.installedServiceURL
    }

    private static func installServiceApp(from serviceURL: URL) throws {
        if FileManager.default.fileExists(atPath: OxxPaths.serviceAppURL.path) {
            try FileManager.default.removeItem(at: OxxPaths.serviceAppURL)
        }
        try FileManager.default.createDirectory(
            at: OxxPaths.serviceAppMacOSURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: OxxPaths.serviceAppContentsURL.appendingPathComponent("Resources", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: serviceURL, to: OxxPaths.installedServiceURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: OxxPaths.installedServiceURL.path
        )
        try infoPlist().write(
            to: OxxPaths.serviceAppContentsURL.appendingPathComponent("Info.plist"),
            atomically: true,
            encoding: .utf8
        )
        try? runCodesign(["--force", "--deep", "--sign", "-", OxxPaths.serviceAppURL.path])
    }

    private static func infoPlist() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleExecutable</key>
            <string>oxx-service</string>
            <key>CFBundleIdentifier</key>
            <string>\(serviceBundleIdentifier)</string>
            <key>CFBundleName</key>
            <string>oxx-service</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>0.1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>LSUIElement</key>
            <true/>
        </dict>
        </plist>
        """
    }

    public static func uninstall() throws {
        _ = try? runLaunchctl(["bootout", userDomain(), OxxPaths.launchAgentURL.path])
        if FileManager.default.fileExists(atPath: OxxPaths.launchAgentURL.path) {
            try FileManager.default.removeItem(at: OxxPaths.launchAgentURL)
        }
    }

    public static func start() throws {
        if FileManager.default.fileExists(atPath: OxxPaths.launchAgentURL.path) {
            try runLaunchctl(["bootstrap", userDomain(), OxxPaths.launchAgentURL.path])
        }
        try runLaunchctl(["kickstart", "-k", "\(userDomain())/\(OxxPaths.label)"])
    }

    public static func stop() throws {
        try runLaunchctl(["bootout", userDomain(), OxxPaths.launchAgentURL.path])
    }

    @discardableResult
    public static func status() throws -> String {
        try runLaunchctlCapturing(["print", "\(userDomain())/\(OxxPaths.label)"])
    }

    public static func userDomain() -> String {
        "gui/\(getuid())"
    }

    @discardableResult
    private static func runLaunchctl(_ arguments: [String]) throws -> String {
        try runLaunchctlCapturing(arguments)
    }

    private static func runLaunchctlCapturing(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorText = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let combined = outputText + errorText
        guard process.terminationStatus == 0 else {
            throw LaunchAgentError.commandFailed("launchctl \(arguments.joined(separator: " ")) \(combined)", process.terminationStatus)
        }
        return combined
    }

    private static func runCodesign(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw LaunchAgentError.commandFailed("codesign \(arguments.joined(separator: " "))", process.terminationStatus)
        }
    }
}

public enum ServiceInstallPolicy {
    public static func shouldReplaceExistingApp(appExists: Bool, forceReplace: Bool) -> Bool {
        !appExists || forceReplace
    }
}
