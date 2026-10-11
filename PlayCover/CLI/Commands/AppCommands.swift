//
//  AppCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct UninstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall an app"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Flag(name: .long, help: "Keep the app's keymaps")
    var keepKeymap = false

    @Flag(name: .long, help: "Keep the app's settings")
    var keepSettings = false

    @Flag(name: .long, help: "Keep the app's entitlements")
    var keepEntitlements = false

    @Flag(name: .long, help: "Keep the app's PlayChain data")
    var keepPlayChain = false

    @Flag(name: .long, help: "Keep the app's container data and caches")
    var keepData = false

    func run() throws {
        let app = CLIAppResolver.require(bundleId)

        let prefs = UninstallPreferences.shared
        if keepKeymap { prefs.removeAppKeymap = false }
        if keepSettings { prefs.removeAppSettings = false }
        if keepEntitlements { prefs.removeAppEntitlements = false }
        if keepPlayChain { prefs.removePlayChain = false }
        if keepData { prefs.clearAppData = false }

        CLIOut.line("Uninstalling \(app.name)...")
        CLIContext.waitForCompletion { done in
            Task {
                await Uninstaller.uninstall(app)
                done()
            }
        }
        CLIOut.line("Uninstalled \(app.name)")
        CLIOut.exit(.success)
    }
}

struct LaunchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "launch",
        abstract: "Launch an installed app"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Flag(name: .long, help: "Launch the app under lldb")
    var lldb = false

    @Flag(name: .long, help: "Launch the app under lldb in a Terminal window")
    var lldbTerminal = false

    func run() throws {
        let app = CLIAppResolver.require(bundleId)

        // Never wait on the interactive KeyCover password prompt in CLI mode.
        KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown = false

        if lldb || lldbTerminal { app.settings.openWithLLDB = true }
        if lldbTerminal { app.settings.openLLDBWithTerminal = true }

        CLIContext.waitForCompletion { done in
            Task {
                await app.launch()
                done()
            }
        }
        CLIOut.line("Launched \(app.name)")
        CLIOut.exit(.success)
    }
}

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed apps"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let apps = CLIAppResolver.fetchApps().map(CLIAppDescription.init)
        if json {
            CLIOut.json(apps)
        } else {
            for app in apps {
                CLIOut.line("\(app.name)\t\(app.bundleIdentifier)\t\(app.version)")
            }
        }
        CLIOut.exit(.success)
    }
}

struct InfoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show details of an installed app"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let app = CLIAppResolver.require(bundleId)

        struct Info: Encodable {
            let name: String
            let bundleName: String
            let bundleIdentifier: String
            let version: String
            let executable: String
            let path: String
            let category: String
            let minimumOSVersion: String
            let hasPlayTools: Bool
            let containerExists: Bool
        }

        let info = Info(
            name: app.name,
            bundleName: app.info.bundleName,
            bundleIdentifier: app.info.bundleIdentifier,
            version: app.info.bundleVersion,
            executable: app.info.executableName,
            path: app.url.path,
            category: app.info.applicationCategoryType.rawValue,
            minimumOSVersion: app.info.minimumOSVersion,
            hasPlayTools: app.hasPlayTools(),
            containerExists: app.container.doesExist()
        )

        if json {
            CLIOut.json(info)
        } else {
            CLIOut.line("Name:            \(info.name)")
            CLIOut.line("Bundle ID:       \(info.bundleIdentifier)")
            CLIOut.line("Version:         \(info.version)")
            CLIOut.line("Category:        \(info.category)")
            CLIOut.line("Minimum OS:      \(info.minimumOSVersion)")
            CLIOut.line("PlayTools:       \(info.hasPlayTools ? "installed" : "not installed")")
            CLIOut.line("Container:       \(info.containerExists ? "exists" : "missing")")
            CLIOut.line("Path:            \(info.path)")
        }
        CLIOut.exit(.success)
    }
}

struct SignCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sign",
        abstract: "Re-sign an installed app"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.sign()
        CLIOut.line("Signed \(app.name)")
        CLIOut.exit(.success)
    }
}

struct AliasCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "alias",
        abstract: "Manage app aliases in ~/Applications/PlayCover",
        subcommands: [AliasCreateCommand.self, AliasRemoveCommand.self]
    )
}

struct AliasCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "create", abstract: "Create an alias")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.createAlias()
        CLIOut.line("Alias created at \(app.aliasURL.path)")
        CLIOut.exit(.success)
    }
}

struct AliasRemoveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "remove", abstract: "Remove an alias")

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.removeAlias()
        CLIOut.line("Alias removed")
        CLIOut.exit(.success)
    }
}

struct ClearCacheCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear-cache",
        abstract: "Clear an app's caches"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        CLIOut.line("Clearing caches for \(app.name)...")
        CLIContext.waitForCompletion { done in
            Task {
                await Uninstaller.clearCache(of: app)
                done()
            }
        }
        CLIOut.line("Caches cleared")
        CLIOut.exit(.success)
    }
}

struct ClearPlayChainCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear-play-chain",
        abstract: "Clear an app's PlayChain data"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.clearPlayChain()
        CLIOut.line("PlayChain cleared")
        CLIOut.exit(.success)
    }
}

struct ShowInFinderCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show-in-finder",
        abstract: "Reveal the app in Finder"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.showInFinder()
        CLIOut.exit(.success)
    }
}

struct OpenContainerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open-container",
        abstract: "Open the app's container in Finder"
    )

    @Argument(help: "Bundle identifier of the app")
    var bundleId: String

    func run() throws {
        let app = CLIAppResolver.require(bundleId)
        app.openAppCache()
        CLIOut.exit(.success)
    }
}
