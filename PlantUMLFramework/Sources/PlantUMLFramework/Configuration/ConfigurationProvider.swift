import Foundation
//import Yams

/// ConfigurationProvider to load `Configuration` from file or memory
public struct ConfigurationProvider {
    /// default initializer
    public init() {}

    /// search for configuration in the given path or the default location (.swiftplantuml) and return it
    /// - Parameter path: file path of configuration file
    /// - Returns: default `Configuration` instance if none was found
    public func getConfiguration(for path: String?) -> Configuration {
        return readSwiftConfig()
    }

    func readSwiftConfig() -> Configuration {
        return defaultConfig
    }

    var defaultConfig: Configuration {
        Configuration.default
    }
}
