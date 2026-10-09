//
//  ToolCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct PlayToolsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "playtools",
        abstract: "Manage PlayTools installation",
        subcommands: [PlayToolsInstallCommand.self]
    )
}

struct PlayToolsInstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "install", abstract: "Install PlayTools on the system")

    func run() throws {
        CLIOut.line("Installing PlayTools...")
        PlayTools.installOnSystem()

        var installed = false
        CLIContext.waitForCompletion { done in
            Task {
                for _ in 0..<600 {
                    if (try? PlayTools.isInstalled()) == true {
                        installed = true
                        done()
                        return
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                done()
            }
        }

        if installed {
            CLIOut.line("PlayTools installed")
            CLIOut.exit(.success)
        } else {
            CLIOut.error("Timed out waiting for PlayTools installation")
            CLIOut.exit(.generalError)
        }
    }
}

struct DylibCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dylib",
        abstract: "Manage user dylibs for an app",
        subcommands: [DylibListCommand.self, DylibAddCommand.self, DylibRemoveCommand.self]
    )
}

struct DylibListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List user dylibs")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        for dylib in PlayTools.userDylibs(bundleIdentifier: app.info.bundleIdentifier) {
            CLIOut.line(dylib.lastPathComponent)
        }
        CLIOut.exit(.success)
    }
}

struct DylibAddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "add", abstract: "Add a user dylib")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Path to the .dylib file")
    var dylibPath: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        let url = URL(fileURLWithPath: (dylibPath as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOut.error("File not found: \(url.path)")
            CLIOut.exit(.badArguments)
        }
        do {
            try PlayTools.addUserDylib(at: url, bundleIdentifier: app.info.bundleIdentifier, appExecutable: app.executable)
            CLIOut.line("Added dylib \(url.lastPathComponent)")
            CLIOut.exit(.success)
        } catch {
            CLIOut.error(error.localizedDescription)
            CLIOut.exit(.generalError)
        }
    }
}

struct DylibRemoveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "remove", abstract: "Remove a user dylib")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Argument(help: "Dylib filename")
    var name: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        do {
            try PlayTools.removeUserDylib(named: name, bundleIdentifier: app.info.bundleIdentifier, appExecutable: app.executable)
            CLIOut.line("Removed dylib \(name)")
            CLIOut.exit(.success)
        } catch {
            CLIOut.error(error.localizedDescription)
            CLIOut.exit(.generalError)
        }
    }
}
