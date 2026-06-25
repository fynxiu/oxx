import Foundation

public enum OxxPaths {
    public static let label = "dev.fyn.oxx"

    public static var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("oxx", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    public static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    public static var logDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("oxx", isDirectory: true)
    }

    public static var applicationSupportDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("oxx", isDirectory: true)
    }

    public static var serviceAppURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("oxx-service.app", isDirectory: true)
    }

    public static var serviceAppContentsURL: URL {
        serviceAppURL.appendingPathComponent("Contents", isDirectory: true)
    }

    public static var serviceAppMacOSURL: URL {
        serviceAppContentsURL.appendingPathComponent("MacOS", isDirectory: true)
    }

    public static var installedServiceURL: URL {
        serviceAppMacOSURL.appendingPathComponent("oxx-service")
    }

    public static var stdoutLogURL: URL {
        logDirectoryURL.appendingPathComponent("service.log")
    }

    public static var stderrLogURL: URL {
        logDirectoryURL.appendingPathComponent("service.err.log")
    }
}
