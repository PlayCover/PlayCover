//
//  SettingsCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct SettingsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "settings",
        abstract: "View and modify per-app settings",
        subcommands: [
            SettingsListCommand.self,
            SettingsGetCommand.self,
            SettingsSetCommand.self,
            SettingsResetCommand.self
        ]
    )
}

struct SettingsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List all settings of an app")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let dict = try CLIAppSettings.dictionary(for: app.settings.settings)
        if json {
            CLIOut.line(try CLIAppSettings.jsonString(dict))
        } else {
            for key in dict.keys.sorted() {
                CLIOut.line("\(key): \(CLIAppSettings.display(dict[key]))")
            }
        }
        CLIOut.exit(.success)
    }
}

struct SettingsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Get a setting value")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Setting key")
    var key: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let dict = try CLIAppSettings.dictionary(for: app.settings.settings)
        guard let value = dict[key] else {
            CLIOut.error("Unknown setting key: \(key)")
            CLIOut.exit(.badArguments)
        }
        CLIOut.line(CLIAppSettings.display(value))
        CLIOut.exit(.success)
    }
}

struct SettingsSetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "set", abstract: "Set a setting value")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Setting key")
    var key: String

    @Argument(help: "New value")
    var value: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)

        if key == "bundleIdentifier" {
            CLIOut.error("bundleIdentifier is read-only")
            CLIOut.exit(.badArguments)
        }

        var dict = try CLIAppSettings.dictionary(for: app.settings.settings)
        guard let current = dict[key] else {
            CLIOut.error("Unknown setting key: \(key)")
            CLIOut.exit(.badArguments)
        }

        // Determine the static type via Mirror so Bool/Int/Float/Double are
        // disambiguated correctly.
        guard let fieldType = CLIAppSettings.fieldType(of: key, in: app.settings.settings) else {
            CLIOut.error("Unknown setting key: \(key)")
            CLIOut.exit(.badArguments)
        }

        switch fieldType {
        case .bool:
            guard let parsed = CLIAppSettings.parseBool(value) else {
                CLIOut.error("Expected a boolean (true/false) for \(key)")
                CLIOut.exit(.badArguments)
            }
            dict[key] = parsed
        case .int:
            guard let parsed = Int(value) else {
                CLIOut.error("Expected an integer for \(key)")
                CLIOut.exit(.badArguments)
            }
            dict[key] = parsed
        case .float, .double:
            guard let parsed = Double(value) else {
                CLIOut.error("Expected a number for \(key)")
                CLIOut.exit(.badArguments)
            }
            dict[key] = parsed
        case .string:
            dict[key] = value
        case .unsupported:
            CLIOut.error("Setting \(key) (type \(String(describing: current))) is not supported by the CLI")
            CLIOut.exit(.badArguments)
        }

        let newSettings = try CLIAppSettings.settings(from: dict)
        app.settings.settings = newSettings

        // The metalHUD didSet side effect only fires on direct mutation,
        // not on wholesale struct replacement — apply it explicitly.
        if key == "metalHUD", let enabled = dict[key] as? Bool {
            do {
                try Shell.setMetalHUD(bundleId, enabled: enabled)
            } catch {
                CLIOut.error(error.localizedDescription)
                CLIOut.exit(.generalError)
            }
        }

        CLIOut.line("\(key) = \(CLIAppSettings.display(dict[key]))")
        CLIOut.exit(.success)
    }
}

struct SettingsResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "reset", abstract: "Reset settings to defaults")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.settings.reset()
        CLIOut.line("Settings reset for \(app.name)")
        CLIOut.exit(.success)
    }
}

enum CLIAppSettings {
    enum FieldType {
        case bool, int, float, double, string, unsupported
    }

    static func dictionary(for settings: AppSettingsData) throws -> [String: Any] {
        let data = try JSONEncoder().encode(settings)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlayCoverError.appCorrupted
        }
        return dict
    }

    static func settings(from dict: [String: Any]) throws -> AppSettingsData {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(AppSettingsData.self, from: data)
    }

    static func fieldType(of key: String, in settings: AppSettingsData) -> FieldType? {
        for child in Mirror(reflecting: settings).children where child.label == key {
            switch child.value {
            case is Bool: return .bool
            case is Int: return .int
            case is Float: return .float
            case is Double: return .double
            case is String: return .string
            default: return .unsupported
            }
        }
        return nil
    }

    static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }

    static func display(_ value: Any?) -> String {
        if let dict = value as? [String: Any], let data = try? jsonString(dict) {
            return data
        }
        return String(describing: value ?? "null")
    }

    static func jsonString(_ dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
