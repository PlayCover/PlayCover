//
//  main.swift
//  PlayCover
//

import Foundation
import AppKit

// Only the first argument being a registered CLI subcommand (or
// -h/--help/--version) enters headless CLI mode. Every other launch
// (double-click, Dock, `open -a`, URL scheme, dropped .ipa) goes through
// the original SwiftUI app unchanged.
if PlayCoverCLI.shouldRunCLI(arguments: CommandLine.arguments) {
    CLIContext.isCLI = true
    _ = NSApplication.shared
    // The CLI is a windowless background process: the .accessory policy keeps it
    // out of the Dock and app switcher, so a bouncing PlayCover icon doesn't appear
    // when launched from the command line (e.g. invoked by other tools / scripts).
    NSApp.setActivationPolicy(.accessory)
    PlayCoverCLI.main()
} else {
    PlayCoverApp.main()
}
