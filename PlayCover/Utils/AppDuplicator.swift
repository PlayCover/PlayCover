//
//  AppDuplicator.swift
//  PlayCover
//

import Darwin
import Foundation

/// Makes a second, independent copy of an installed app so that both can be played at the same
/// time, each signed into its own account.
///
/// Everything PlayCover keeps for an app - its container, settings, keymaps, entitlements and
/// PlayChain - is stored under that app's bundle identifier, so a copy only needs an identifier of
/// its own to get all of those separately. That is all a duplicate is: the same bundle under a new
/// identifier and a new name, signed again, with the original's settings and keymaps carried over
/// so that it starts out playing the same way.
///
/// App data is deliberately not carried over. The reason to want a second copy is a second
/// account, and a copy of a container that is already signed in is not that.
class AppDuplicator {

    /// Last component PlayCover puts on a copy's bundle identifier. It is what tells a copy apart
    /// from the app it was made from, so that copies of a copy are numbered from the original
    /// rather than growing a suffix every time.
    private static let copySuffix = "copy"

    // MARK: - Naming

    /// The identifier and name to offer for the next copy of `app`, skipping any that are taken.
    static func suggestedCopy(of app: PlayApp) -> (bundleIdentifier: String, name: String) {
        let baseIdentifier = originalIdentifier(of: app.info.bundleIdentifier)
        let baseName = originalName(of: app)
        let takenNames = Set(AppsVM.shared.apps.map({ $0.name }))

        var index = 2
        while true {
            let identifier = "\(baseIdentifier).\(copySuffix)\(index)"
            let name = "\(baseName) \(index)"

            // The name matters as much as the identifier: the alias in ~/Applications/PlayCover is
            // named after the app, so two apps sharing a name would share an alias.
            if !FileManager.default.fileExists(atPath: bundleURL(for: identifier).path),
               !takenNames.contains(name) {
                return (identifier, name)
            }

            index += 1
        }
    }

    private static func originalIdentifier(of identifier: String) -> String {
        let components = identifier.components(separatedBy: ".")

        guard let last = components.last,
              last.hasPrefix(copySuffix),
              Int(last.dropFirst(copySuffix.count)) != nil else {
            return identifier
        }

        return components.dropLast().joined(separator: ".")
    }

    private static func originalName(of app: PlayApp) -> String {
        let identifier = originalIdentifier(of: app.info.bundleIdentifier)

        guard identifier != app.info.bundleIdentifier else { return app.name }

        // This app is itself a copy, so number the new one from the app it was made from. If that
        // one has since been uninstalled, fall back to taking off the number PlayCover added.
        if let original = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == identifier }) {
            return original.name
        }

        return app.name.replacingOccurrences(of: " [0-9]+$", with: "", options: .regularExpression)
    }

    /// `name` if no other app is called that, and otherwise `name` with a number on the end. Two
    /// apps sharing a name would share an alias in ~/Applications/PlayCover, and the second one to
    /// be created would silently end up launching the first.
    private static func availableName(_ name: String) -> String {
        let takenNames = Set(AppsVM.shared.apps.map({ $0.name }))

        guard takenNames.contains(name) else { return name }

        var index = 2
        while takenNames.contains("\(name) \(index)") {
            index += 1
        }

        return "\(name) \(index)"
    }

    private static func bundleURL(for identifier: String) -> URL {
        AppsVM.appDirectory
            .appendingEscapedPathComponent(identifier)
            .appendingPathExtension("app")
    }

    // MARK: - Duplication

    /// Copies `app` into the library as a separate app, and returns it.
    static func duplicate(_ app: PlayApp, identifier: String, name: String) throws -> PlayApp {
        let destination = bundleURL(for: identifier)

        guard !FileManager.default.fileExists(atPath: destination.path) else {
            throw PlayCoverError.duplicateExists
        }

        InstallVM.shared.next(.duplicate, 0.0, 0.7)

        do {
            try copyBundle(from: app.url, to: destination)
            try rewriteIdentifiers(in: destination, from: app.info.bundleIdentifier, to: identifier, name: name)
            copyEntitlements(from: app.info.bundleIdentifier, to: identifier)
        } catch {
            // A half-copied bundle would show up in the library as a broken app, so it does not
            // get to outlive the failure that produced it.
            FileManager.default.delete(at: destination)
            throw error
        }

        // Creating the app is what gives it its alias, settings and keymap directory, so it has to
        // happen after the identifier and the name are in place.
        let duplicate = PlayApp(appUrl: destination)
        copySettings(from: app, to: duplicate)
        duplicate.keymapping.adoptKeymaps(of: app.keymapping)

        InstallVM.shared.next(.sign, 0.7, 0.9)
        duplicate.sign()

        return duplicate
    }

    /// APFS can clone a bundle rather than copy it: the copy is made at once and takes up no extra
    /// space until one of the two is written to. Games run to tens of gigabytes, so this is what
    /// makes duplicating one of them reasonable. Volumes that cannot clone fall back to a copy.
    private static func copyBundle(from source: URL, to destination: URL) throws {
        if clonefile(source.path, destination.path, 0) == 0 { return }

        try FileManager.default.copyItem(at: source, to: destination)
    }

    private static func rewriteIdentifiers(in bundle: URL,
                                           from oldIdentifier: String,
                                           to identifier: String,
                                           name: String) throws {
        let info = AppInfo(contentsOf: bundle
            .appendingPathComponent("Info")
            .appendingPathExtension("plist"))

        info[string: "CFBundleIdentifier"] = identifier
        info[string: "CFBundleName"] = name
        info[string: "CFBundleDisplayName"] = name
        try info.write()

        // App extensions have to stay underneath their host app's identifier, so they move with
        // it. Frameworks are left alone: nothing requires them to be renamed, and apps do look
        // their own frameworks up by identifier.
        let plugIns = bundle.appendingPathComponent("PlugIns")
        guard let contents = try? FileManager.default.contentsOfDirectory(at: plugIns,
                                                                          includingPropertiesForKeys: nil) else {
            return
        }

        for plugIn in contents where plugIn.pathExtension == "appex" {
            let plugInInfo = AppInfo(contentsOf: plugIn
                .appendingPathComponent("Info")
                .appendingPathExtension("plist"))

            guard plugInInfo.bundleIdentifier.hasPrefix(oldIdentifier) else { continue }

            let remainder = plugInInfo.bundleIdentifier.dropFirst(oldIdentifier.count)
            plugInInfo[string: "CFBundleIdentifier"] = identifier + remainder
            try plugInInfo.write()
        }
    }

    /// Carries over the entitlements dumped from the original when it was installed, which is
    /// where the app's own entitlements live once PlaySign has been set up.
    private static func copyEntitlements(from oldIdentifier: String, to identifier: String) {
        let source = Entitlements.playCoverEntitlementsDir
            .appendingPathComponent(oldIdentifier)
            .appendingPathExtension("plist")
        let destination = Entitlements.playCoverEntitlementsDir
            .appendingPathComponent(identifier)
            .appendingPathExtension("plist")

        guard FileManager.default.fileExists(atPath: source.path) else { return }

        FileManager.default.delete(at: destination)

        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            Log.shared.error(error)
        }
    }

    private static func copySettings(from app: PlayApp, to duplicate: PlayApp) {
        var settings = app.settings.settings
        settings.bundleIdentifier = duplicate.info.bundleIdentifier
        duplicate.settings.settings = settings
    }

    // MARK: - UI

    @MainActor
    static func duplicatePopup(_ app: PlayApp) async {
        let suggested = suggestedCopy(of: app)

        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        nameField.stringValue = suggested.name
        nameField.placeholderString = suggested.name

        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("playapp.duplicateMessage", comment: ""),
                                   arguments: [app.name])
        alert.informativeText = NSLocalizedString("playapp.duplicateInformative", comment: "")
        alert.alertStyle = .informational
        alert.accessoryView = nameField
        alert.addButton(withTitle: NSLocalizedString("playapp.duplicateConfirm", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
        alert.window.initialFirstResponder = nameField

        guard let window = NSApplication.shared.windows.first,
              await alert.beginSheetModal(for: window) == .alertFirstButtonReturn else { return }

        let typedName = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = availableName(typedName.isEmpty ? suggested.name : typedName)

        InstallVM.shared.next(.begin, 0.0, 0.0)

        Task(priority: .userInitiated) {
            do {
                let duplicate = try duplicate(app, identifier: suggested.bundleIdentifier, name: name)

                InstallVM.shared.next(.library, 0.9, 0.95)
                AppsVM.shared.fetchApps()

                InstallVM.shared.next(.finish, 0.95, 1.0)
                await MainActor.run {
                    ToastVM.shared.showToast(
                        toastType: .notice,
                        toastDetails: String(format: NSLocalizedString("playapp.duplicateFinished", comment: ""),
                                             arguments: [duplicate.name]))
                }
            } catch {
                Log.shared.error(error)
                InstallVM.shared.next(.failed, 0.95, 1.0)
            }
        }
    }
}
