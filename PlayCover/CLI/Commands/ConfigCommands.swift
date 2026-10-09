//
//  ConfigCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "View and modify global preferences",
        subcommands: [ConfigListCommand.self, ConfigGetCommand.self, ConfigSetCommand.self]
    )
}

enum CLIConfig {
    static let allowedKeys: [String] = [
        "AlwaysInstallPlayTools", "DefaultAppType", "ShowInstallPopup",
        "ShowAppStorePopup", "ShowUninstallPopup", "ClearAppDataUninstall",
        "RemoveAppKeymapUninstall", "RemoveAppSettingUninstall",
        "RemoveAppEntitlementsUninstall", "RemovePlayChainUninstall",
        "SUEnableAutomaticChecks", "keyCoverEnabled",
        "promptForKeyCoverPasswordAtLaunch"
    ]

    static func validateKey(_ key: String) {
        if !allowedKeys.contains(key) {
            CLIOut.error("Key '\(key)' is not in the CLI-configurable list")
            CLIOut.exit(.badArguments)
        }
    }
}

struct ConfigListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List configurable preferences")

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        var dict: [String: Any] = [:]
        for key in CLIConfig.allowedKeys {
            dict[key] = UserDefaults.standard.object(forKey: key) ?? NSNull()
        }
        if json {
            CLIOut.line(try CLIAppSettings.jsonString(dict))
        } else {
            for key in CLIConfig.allowedKeys.sorted() {
                CLIOut.line("\(key): \(CLIAppSettings.display(dict[key]))")
            }
        }
        CLIOut.exit(.success)
    }
}

struct ConfigGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "get", abstract: "Get a preference value")

    @Argument(help: "Preference key")
    var key: String

    func run() throws {
        CLIConfig.validateKey(key)
        CLIOut.line(CLIAppSettings.display(UserDefaults.standard.object(forKey: key)))
        CLIOut.exit(.success)
    }
}

struct ConfigSetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "set", abstract: "Set a preference value")

    @Argument(help: "Preference key")
    var key: String

    @Argument(help: "New value")
    var value: String

    func run() throws {
        CLIConfig.validateKey(key)

        // Preserve the existing type when possible.
        let current = UserDefaults.standard.object(forKey: key)
        if let boolValue = current as? Bool {
            guard let parsed = CLIAppSettings.parseBool(value) else {
                CLIOut.error("Expected a boolean (true/false) for \(key)")
                CLIOut.exit(.badArguments)
            }
            UserDefaults.standard.set(parsed, forKey: key)
            _ = boolValue
        } else if current is Int {
            guard let parsed = Int(value) else {
                CLIOut.error("Expected an integer for \(key)")
                CLIOut.exit(.badArguments)
            }
            UserDefaults.standard.set(parsed, forKey: key)
        } else if current is Double {
            guard let parsed = Double(value) else {
                CLIOut.error("Expected a number for \(key)")
                CLIOut.exit(.badArguments)
            }
            UserDefaults.standard.set(parsed, forKey: key)
        } else if let parsed = CLIAppSettings.parseBool(value) {
            // New keys are usually toggles; accept bool when there is no
            // existing value.
            UserDefaults.standard.set(parsed, forKey: key)
        } else {
            UserDefaults.standard.set(value, forKey: key)
        }

        CLIOut.line("\(key) = \(value)")
        CLIOut.exit(.success)
    }
}

struct PruneCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "prune", abstract: "Remove orphaned files")

    func run() throws {
        Uninstaller.pruneFiles()
        CLIOut.line("Pruned orphaned files")
        CLIOut.exit(.success)
    }
}
