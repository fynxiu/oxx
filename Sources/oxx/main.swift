import Foundation
import OxxCore

@main
struct OxxCLI {
    static func main() {
        do {
            try run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("error: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }

    static func run(_ arguments: [String]) throws {
        guard let command = arguments.first else {
            printUsage()
            return
        }

        switch command {
        case "help", "--help", "-h":
            printUsage()
        case "list-displays":
            try listDisplays()
        case "jump":
            try jump(arguments)
        case "config":
            try config(arguments)
        case "install":
            try install(arguments)
        case "upgrade":
            try install(arguments, forceReplace: true)
        case "uninstall":
            try LaunchAgentManager.uninstall()
            print("Uninstalled \(OxxPaths.label).")
        case "start":
            try LaunchAgentManager.start()
            print("Started \(OxxPaths.label).")
        case "stop":
            try LaunchAgentManager.stop()
            print("Stopped \(OxxPaths.label).")
        case "restart":
            try? LaunchAgentManager.stop()
            try LaunchAgentManager.start()
            print("Restarted \(OxxPaths.label).")
        case "status":
            print(try LaunchAgentManager.status())
        case "permissions":
            printPermissions(prompt: arguments.contains("--prompt"))
        case "service-permissions":
            try servicePermissions()
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    static func listDisplays() throws {
        let displays = try DisplayRuntime.orderedDisplays()
        guard !displays.isEmpty else {
            print("No active displays found.")
            return
        }

        for (index, display) in displays.enumerated() {
            let bounds = display.bounds
            let center = display.center
            let main = display.isMain ? "yes" : "no"
            print(
                "[\(index)] id=\(display.id) main=\(main) " +
                "bounds=(x:\(format(bounds.minX)), y:\(format(bounds.minY)), w:\(format(bounds.width)), h:\(format(bounds.height))) " +
                "center=(x:\(format(center.x)), y:\(format(center.y)))"
            )
        }
    }

    static func jump(_ arguments: [String]) throws {
        guard arguments.count == 2, let rawIndex = arguments.dropFirst().first, let index = Int(rawIndex) else {
            throw CLIError.usage("Usage: oxx jump <display-index>")
        }
        let display = try DisplayRuntime.jumpToDisplay(index: index)
        print("Moved cursor to display \(index) center at x=\(format(display.center.x)), y=\(format(display.center.y)).")
    }

    static func config(_ arguments: [String]) throws {
        guard arguments.count >= 2 else {
            throw CLIError.usage("Usage: oxx config <init|path|show|validate>")
        }

        switch arguments[1] {
        case "init":
            try ConfigStore.write(.default)
            print("Wrote default config to \(OxxPaths.configURL.path).")
        case "path":
            print(OxxPaths.configURL.path)
        case "show":
            let config = try ConfigStore.loadOrCreateDefault()
            print(String(data: try config.encodedPretty(), encoding: .utf8)!)
        case "validate":
            _ = try ConfigStore.validate()
            print("Config OK: \(OxxPaths.configURL.path)")
        default:
            throw CLIError.usage("Usage: oxx config <init|path|show|validate>")
        }
    }

    static func install(_ arguments: [String], forceReplace: Bool = false) throws {
        let serviceURL: URL
        if let pathIndex = arguments.firstIndex(of: "--service-path"), arguments.indices.contains(pathIndex + 1) {
            serviceURL = URL(fileURLWithPath: arguments[pathIndex + 1])
        } else {
            serviceURL = try defaultServiceURL()
        }

        let requestedForceReplace = forceReplace || arguments.contains("--replace-service")
        let appExisted = FileManager.default.fileExists(atPath: OxxPaths.installedServiceURL.path)
        let installedServiceURL = try LaunchAgentManager.install(serviceURL: serviceURL, forceReplace: requestedForceReplace)
        if appExisted && !requestedForceReplace {
            print("Reused existing service app to preserve Accessibility permission.")
        } else {
            print("Installed service app.")
        }
        print("Installed \(OxxPaths.label).")
        print("LaunchAgent: \(OxxPaths.launchAgentURL.path)")
        print("Config: \(OxxPaths.configURL.path)")
        print("Service binary: \(installedServiceURL.path)")
        if requestedForceReplace {
            print("The service app was replaced. macOS may require toggling Accessibility permission for ~/Applications/oxx-service.app.")
        }
        print("Grant Accessibility permission to the service binary if middle-click cycling does not work.")
        print(AccessibilityPermissions.guidance)
    }

    static func servicePermissions() throws {
        let serviceURL = OxxPaths.installedServiceURL
        guard FileManager.default.isExecutableFile(atPath: serviceURL.path) else {
            throw LaunchAgentError.serviceBinaryMissing(serviceURL)
        }

        let process = Process()
        process.executableURL = serviceURL
        process.arguments = ["--check-accessibility"]
        try process.run()
        process.waitUntilExit()
        Foundation.exit(process.terminationStatus)
    }

    static func defaultServiceURL() throws -> URL {
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let sibling = executableURL.deletingLastPathComponent().appendingPathComponent("oxx-service")
        if FileManager.default.isExecutableFile(atPath: sibling.path) {
            return sibling
        }

        let release = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("release", isDirectory: true)
            .appendingPathComponent("oxx-service")
        if FileManager.default.isExecutableFile(atPath: release.path) {
            return release
        }

        throw LaunchAgentError.serviceBinaryMissing(sibling)
    }

    static func printPermissions(prompt: Bool) {
        if AccessibilityPermissions.isTrusted(prompt: prompt) {
            print("Accessibility permission for this process: granted")
        } else {
            print("Accessibility permission for this process: missing")
            print(AccessibilityPermissions.guidance)
            print("Settings URL: \(AccessibilityPermissions.settingsURL)")
        }
    }

    static func printUsage() {
        print(
            """
            Usage: oxx <command>

            Commands:
              list-displays              List active displays in cycle order
              jump <display-index>       Move cursor to a display center
              install [--service-path]   Install/start without replacing an existing service app
              upgrade [--service-path]   Replace the service app, then install/start
              uninstall                  Stop and remove the user LaunchAgent
              start|stop|restart|status  Manage the LaunchAgent
              config init|path|show|validate
              permissions [--prompt]     Check Accessibility permission
              service-permissions         Check Accessibility for installed oxx-service
            """
        )
    }

    static func format(_ value: CGFloat) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.2f", Double(value))
    }
}

enum CLIError: Error, CustomStringConvertible {
    case unknownCommand(String)
    case usage(String)

    var description: String {
        switch self {
        case .unknownCommand(let command):
            return "Unknown command '\(command)'. Run `oxx help`."
        case .usage(let message):
            return message
        }
    }
}
