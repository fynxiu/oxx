import Foundation

public enum ConfigStore {
    public static func loadOrCreateDefault(at url: URL = OxxPaths.configURL) throws -> OxxConfig {
        if FileManager.default.fileExists(atPath: url.path) {
            return try OxxConfig.decode(Data(contentsOf: url))
        }

        try write(.default, to: url)
        return .default
    }

    public static func write(_ config: OxxConfig, to url: URL = OxxPaths.configURL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try config.encodedPretty().write(to: url, options: [.atomic])
    }

    public static func validate(at url: URL = OxxPaths.configURL) throws -> OxxConfig {
        try loadOrCreateDefault(at: url)
    }
}
