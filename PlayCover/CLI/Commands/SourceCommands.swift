//
//  SourceCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct SourceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "source",
        abstract: "Manage IPA sources",
        subcommands: [
            SourceListCommand.self,
            SourceAddCommand.self,
            SourceRemoveCommand.self,
            SourceRefreshCommand.self,
            SourceEnableCommand.self,
            SourceDisableCommand.self
        ]
    )
}

struct CLISourceDescription: Encodable {
    let id: String
    let source: String
    let enabled: Bool
}

struct SourceListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List configured sources")

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let vm = StoreVM.shared
        if json {
            CLIOut.json(vm.sourcesList.map {
                CLISourceDescription(id: $0.id.uuidString, source: $0.source, enabled: $0.isEnabled)
            })
        } else {
            for source in vm.sourcesList {
                CLIOut.line("[\(source.isEnabled ? "x" : " ")] \(source.source)  (\(source.status))")
            }
        }
        CLIOut.exit(.success)
    }
}

struct SourceAddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "add", abstract: "Add a source")

    @Argument(help: "Source URL")
    var url: String

    func run() throws {
        let data = SourceData(source: url, isEnabled: true)
        StoreVM.shared.addSource(data)
        CLIOut.line("Added source \(url)")
        CLIOut.exit(.success)
    }
}

struct SourceRemoveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "remove", abstract: "Remove source(s) by URL")

    @Argument(help: "Source URL")
    var url: String

    func run() throws {
        var ids = Set(StoreVM.shared.sourcesList.filter { $0.source == url }.map(\.id))
        StoreVM.shared.deleteSource(&ids)
        CLIOut.line("Removed \(url)")
        CLIOut.exit(.success)
    }
}

struct SourceRefreshCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "refresh", abstract: "Refresh all sources")

    func run() throws {
        StoreVM.shared.resolveSources()
        CLIContext.waitForCompletion { done in
            Task {
                await StoreVM.shared.awaitResolveSources()
                done()
            }
        }
        CLIOut.line("Sources refreshed")
        CLIOut.exit(.success)
    }
}

struct SourceEnableCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "enable", abstract: "Enable a source")

    @Argument(help: "Source URL")
    var url: String

    func run() throws {
        guard let source = StoreVM.shared.sourcesList.first(where: { $0.source == url }) else {
            CLIOut.error("Source not found: \(url)")
            CLIOut.exit(.appNotFound)
        }
        StoreVM.shared.enableSourceToggle(source: source, value: true)
        CLIOut.line("Enabled \(url)")
        CLIOut.exit(.success)
    }
}

struct SourceDisableCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "disable", abstract: "Disable a source")

    @Argument(help: "Source URL")
    var url: String

    func run() throws {
        guard let source = StoreVM.shared.sourcesList.first(where: { $0.source == url }) else {
            CLIOut.error("Source not found: \(url)")
            CLIOut.exit(.appNotFound)
        }
        StoreVM.shared.enableSourceToggle(source: source, value: false)
        CLIOut.line("Disabled \(url)")
        CLIOut.exit(.success)
    }
}
