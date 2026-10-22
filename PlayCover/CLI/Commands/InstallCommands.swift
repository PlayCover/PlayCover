//
//  InstallCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct InstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install an IPA file"
    )

    @Argument(help: "Path to the .ipa file")
    var ipaPath: String

    @Flag(name: .long, help: "Install PlayTools into the app")
    var playTools = false

    @Flag(name: .long, help: "Do not install PlayTools into the app")
    var noPlayTools = false

    @Option(name: .long, help: "App category (e.g. games, utilities)")
    var category: String?

    func run() throws {
        if playTools && noPlayTools {
            throw ValidationError("Use either --play-tools or --no-play-tools, not both.")
        }
        CLIContext.playToolsOverride = playTools ? true : (noPlayTools ? false : nil)

        if let category = category {
            guard let parsed = CLICommandUtils.parseCategory(category) else {
                throw ValidationError("Unknown category: \(category)")
            }
            CLIContext.appCategoryOverride = parsed
        }

        let url = URL(fileURLWithPath: (ipaPath as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOut.error("File not found: \(url.path)")
            CLIOut.exit(.badArguments)
        }

        var resultURL: URL?
        CLIContext.waitForCompletion { done in
            Installer.install(ipaUrl: url, export: false) { finalURL in
                resultURL = finalURL
                done()
            }
        }
        CLIProgressRenderer.shared.terminateLineIfNeeded()

        guard let resultURL = resultURL else {
            CLIOut.exit(.generalError)
        }
        AppsVM.shared.fetchApps()
        CLIOut.line("Installed: \(resultURL.path)")
        CLIOut.exit(.success)
    }
}

struct ExportCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Inject PlayTools into an IPA and export it"
    )

    @Argument(help: "Path to the .ipa file")
    var ipaPath: String

    @Option(name: [.short, .long], help: "Output path of the exported .ipa")
    var output: String

    func run() throws {
        let url = URL(fileURLWithPath: (ipaPath as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOut.error("File not found: \(url.path)")
            CLIOut.exit(.badArguments)
        }

        var resultURL: URL?
        CLIContext.waitForCompletion { done in
            Installer.install(ipaUrl: url, export: true) { finalURL in
                resultURL = finalURL
                done()
            }
        }
        CLIProgressRenderer.shared.terminateLineIfNeeded()

        guard let resultURL = resultURL else {
            CLIOut.exit(.generalError)
        }

        let destination = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: resultURL, to: destination)
        } catch {
            CLIOut.error(error.localizedDescription)
            CLIOut.exit(.generalError)
        }
        CLIOut.line("Exported: \(destination.path)")
        CLIOut.exit(.success)
    }
}

enum CLICommandUtils {
    static func parseCategory(_ value: String) -> LSApplicationCategoryType? {
        let raw = value.contains(".") ? value : "public.app-category.\(value.lowercased())"
        return LSApplicationCategoryType(rawValue: raw)
    }
}
