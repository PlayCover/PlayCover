//
//  PlayCoverCLI.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct PlayCoverCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "playcover",
        abstract: "PlayCover command line interface",
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        subcommands: [
            InstallCommand.self,
            ExportCommand.self,
            UninstallCommand.self,
            LaunchCommand.self,
            ListCommand.self,
            InfoCommand.self,
            SignCommand.self,
            AliasCommand.self,
            ClearCacheCommand.self,
            ClearPlayChainCommand.self,
            ShowInFinderCommand.self,
            OpenContainerCommand.self,
            SettingsCommand.self,
            KeymapCommand.self,
            SourceCommand.self,
            StoreCommand.self,
            DownloadCommand.self,
            PlayToolsCommand.self,
            DylibCommand.self,
            ConfigCommand.self,
            PruneCommand.self
        ]
    )

    /// Only these tokens (or -h/--help/--version) as the very first argument
    /// switch the process into CLI mode; anything else boots the GUI.
    static let subcommandNames: Set<String> = [
        "install", "export", "uninstall", "launch", "list", "info", "sign",
        "alias", "clear-cache", "clear-play-chain", "show-in-finder", "open-container",
        "settings", "keymap", "source", "store", "download", "playtools",
        "dylib", "config", "prune"
    ]

    static func shouldRunCLI(arguments: [String]) -> Bool {
        guard arguments.count > 1 else { return false }
        let first = arguments[1]
        if ["-h", "--help", "--version"].contains(first) { return true }
        return subcommandNames.contains(first)
    }
}

/// Helpers shared by CLI commands that work with installed apps.
enum CLIAppResolver {
    /// Refreshes the app list and blocks until the refresh finished.
    static func fetchApps() -> [PlayApp] {
        let vm = AppsVM.shared
        vm.fetchApps()
        CLIContext.waitForCompletion { done in
            Task { @MainActor in
                while AppsVM.shared.updatingApps {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                done()
            }
        }
        return AppsVM.shared.apps
    }

    static func find(_ bundleId: String) -> PlayApp? {
        fetchApps().first { $0.info.bundleIdentifier == bundleId }
    }

    static func require(_ bundleId: String) -> PlayApp {
        guard let app = find(bundleId) else {
            CLIOut.error("App not found: \(bundleId)")
            CLIOut.exit(.appNotFound)
        }
        return app
    }
}

/// Encodable snapshot of an installed app for text/JSON output.
struct CLIAppDescription: Encodable {
    let name: String
    let bundleIdentifier: String
    let version: String
    let path: String

    init(_ app: PlayApp) {
        name = app.name
        bundleIdentifier = app.info.bundleIdentifier
        version = app.info.bundleVersion
        path = app.url.path
    }
}
