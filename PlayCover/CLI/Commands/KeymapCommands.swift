//
//  KeymapCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct KeymapCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keymap",
        abstract: "Manage keymaps for an app",
        subcommands: [
            KeymapListCommand.self,
            KeymapCreateCommand.self,
            KeymapDeleteCommand.self,
            KeymapRenameCommand.self,
            KeymapSetDefaultCommand.self,
            KeymapResetCommand.self,
            KeymapImportCommand.self,
            KeymapExportCommand.self
        ]
    )
}

struct KeymapListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List keymaps")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        for url in app.keymapping.keymapConfig.keymapOrder {
            CLIOut.line(url.deletingPathExtension().lastPathComponent)
        }
        CLIOut.exit(.success)
    }
}

struct KeymapCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "create", abstract: "Create an empty keymap")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        if app.keymapping.createEmptyKeymap(name: name) {
            CLIOut.line("Created keymap '\(name)'")
        } else {
            CLIOut.error("Could not create keymap '\(name)'")
            CLIOut.exit(.generalError)
        }
        CLIOut.exit(.success)
    }
}

struct KeymapDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "delete", abstract: "Delete a keymap")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        if app.keymapping.deleteKeymap(name: name) {
            CLIOut.line("Deleted keymap '\(name)'")
        } else {
            CLIOut.error("Could not delete keymap '\(name)'")
            CLIOut.exit(.generalError)
        }
        CLIOut.exit(.success)
    }
}

struct KeymapRenameCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "rename", abstract: "Rename a keymap")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Current keymap name")
    var oldName: String

    @Argument(help: "New keymap name")
    var newName: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        if app.keymapping.renameKeymap(prevName: oldName, newName: newName) {
            CLIOut.line("Renamed '\(oldName)' -> '\(newName)'")
        } else {
            CLIOut.error("Could not rename keymap")
            CLIOut.exit(.generalError)
        }
        CLIOut.exit(.success)
    }
}

struct KeymapSetDefaultCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "set-default", abstract: "Set the default keymap")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let path = app.keymapping.baseKeymapURL.appendingPathComponent(name).appendingPathExtension("plist")
        guard app.keymapping.keymapConfig.keymapOrder.contains(path) else {
            CLIOut.error("Keymap '\(name)' not found")
            CLIOut.exit(.badArguments)
        }
        app.keymapping.keymapConfig.defaultKm = path
        CLIOut.line("Default keymap set to '\(name)'")
        CLIOut.exit(.success)
    }
}

struct KeymapResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "reset", abstract: "Reset a keymap to defaults")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        _ = app.keymapping.reset(name: name)
        CLIOut.line("Reset keymap '\(name)'")
        CLIOut.exit(.success)
    }
}

struct KeymapImportCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "import", abstract: "Import a keymap from file")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    @Argument(help: "Path to the .playmap or .plist file")
    var filePath: String

    @Flag(name: .long, help: "Skip bundle identifier mismatch confirmation")
    var force = false

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let path = URL(fileURLWithPath: (filePath as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: path.path) else {
            CLIOut.error("File not found: \(path.path)")
            CLIOut.exit(.badArguments)
        }

        let keymap: Keymap
        do {
            let data = try Data(contentsOf: path)
            keymap = try PropertyListDecoder().decode(Keymap.self, from: data)
        } catch {
            if let converted = LegacySettings.convertLegacyKeymapFile(path) {
                keymap = converted
            } else {
                CLIOut.error("Failed to read keymap: \(error.localizedDescription)")
                CLIOut.exit(.generalError)
            }
        }

        if keymap.bundleIdentifier != bundleId && !force {
            CLIOut.error("Bundle ID mismatch: keymap has '\(keymap.bundleIdentifier)', app is '\(bundleId)'. Use --force to override.")
            CLIOut.exit(.verificationFailed)
        }

        app.keymapping.setKeymap(name: name, map: keymap)
        CLIOut.line("Imported '\(name)'")
        CLIOut.exit(.success)
    }
}

struct KeymapExportCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "export", abstract: "Export a keymap to file")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Keymap name")
    var name: String

    @Option(name: [.short, .long], help: "Output file path")
    var output: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let destination = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
        let data = try app.keymapping.encoder.encode(app.keymapping.getKeymap(name: name))
        try data.write(to: destination)
        CLIOut.line("Exported to \(destination.path)")
        CLIOut.exit(.success)
    }
}
