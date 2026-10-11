//
//  StoreCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct StoreCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "store",
        abstract: "Browse available apps from sources",
        subcommands: [StoreListCommand.self]
    )
}

struct StoreListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List available apps")

    @Option(name: .long, help: "Filter by source URL")
    var source: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let vm = StoreVM.shared
        vm.resolveSources()
        CLIContext.waitForCompletion { done in
            Task {
                await StoreVM.shared.awaitResolveSources()
                done()
            }
        }

        var apps = vm.sourcesApps
        if let source = source {
            if let src = vm.sourcesList.first(where: { $0.source == source }),
               let json = vm.sourcesData.first(where: { $0.id == src.id }) {
                apps = json.data
            } else {
                apps = []
            }
        }

        if json {
            CLIOut.json(apps.map {
                ["name": $0.name,
                 "bundleID": $0.bundleID,
                 "version": $0.version,
                 "link": $0.link,
                 "checksum": $0.checksum ?? ""]
            })
        } else {
            for app in apps {
                CLIOut.line("\(app.bundleID)\t\(app.name)\t\(app.version)\t\(app.link)")
            }
        }
        CLIOut.exit(.success)
    }
}
