//
//  AppSettings.swift
//  PlayCover
//

import Foundation
import UniformTypeIdentifiers
import AppKit

let notchModels = [ "MacBookPro18,3", "MacBookPro18,4", "MacBookPro18,1", "MacBookPro18,2", "Mac14,2"]

extension NSScreen {

    public static func hasNotch() -> Bool {
        if let model = NSScreen.getMacModel() {
            return notchModels.contains(model)
        } else {
            return false
        }
    }

    private static func getMacModel() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?

        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data {
            if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
                modelIdentifier = String(cString: modelIdentifierCString)
            }
        }

        IOObjectRelease(service)
        return modelIdentifier
    }

}

class AppSettings {

    let info: AppInfo
    var container: AppContainer?

    public static let settingsUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Preferences/playcover.plist")

    public func sync() {
        notch = NSScreen.hasNotch()
    }

    private static let gamingMode = "pc.gamingMode"
    var gamingMode: Bool {
        get {
            return dictionary[AppSettings.gamingMode] as? Bool ?? info.isGame
        }
        set {
            var dict = dictionary
            dict[AppSettings.gamingMode] = newValue
            dictionary = dict
        }
    }

    private static let notch = "pc.hasNotch"
    var notch: Bool {
        get {
            return NSScreen.hasNotch()
        }
        set {
            var dict = dictionary
            dict[AppSettings.notch] = newValue
            dictionary = dict
        }
    }

    private static let layout = "pc.layout"
    var layout: [[CGFloat]] {
        get {
            return dictionary[AppSettings.layout] as? Array ?? []
        }
        set {
            var dict = dictionary
            dict[AppSettings.layout] = newValue
            dictionary = dict
        }
    }

    private static let sensivity = "pc.sensivity"
    var sensivity: Float {
        get {
            return dictionary[AppSettings.sensivity] as? Float ?? 50
        }
        set {
            var dict = dictionary
            dict[AppSettings.sensivity] = newValue
            dictionary = dict
        }
    }

    private static let refreshRate = "pc.refreshRate"
    var refreshRate: Int {
        get {
            return dictionary[AppSettings.refreshRate] as? Int ?? 60
        }
        set {
            var dict = dictionary
            dict[AppSettings.refreshRate] = newValue
            dictionary = dict
        }
    }
<<<<<<< HEAD

    private static let bypass = "pc.bypass"
    var bypass: Bool {
        get {
            return dictionary[AppSettings.bypass] as? Bool ?? false
        }
        set {
            var dict = dictionary
            dict[AppSettings.bypass] = newValue
            dictionary = dict
        }
    }
    private static let keymapping = "pc.keymapping"
    var keymapping: Bool {
        get {
            return dictionary[AppSettings.keymapping] as? Bool ?? info.isGame
        }
        set {
            var dict = dictionary
            dict[AppSettings.keymapping] = newValue
            dictionary = dict
        }
    }

    private static let adaptiveDisplay = "pc.adaptiveDisplay"
    var adaptiveDisplay: Bool {
        get {
            dictionary[AppSettings.adaptiveDisplay] as? Bool ?? info.isGame
        }
        set {
            var dict = dictionary
            dict[AppSettings.adaptiveDisplay] = newValue
            dictionary = dict
        }
    }

    private var allPrefs: [String: Any] {
        get {
            do {
                if let all = try [String: Any].read(AppSettings.settingsUrl) {
                    if !all.isEmpty {
                        return all
                    }
                }
            } catch {
                Log.shared.error(error)
            }
            return [:]
        }
        set {
            do {
                try newValue.store(AppSettings.settingsUrl)
            } catch {
                Log.shared.error(error)
            }
        }
    }

    private var dictionary: [String: Any] {
        get {
            if let prefs = allPrefs[info.bundleIdentifier] as? [String: Any] {
                return prefs
            } else {
                return [AppSettings.keymapping: info.isGame, AppSettings.adaptiveDisplay: info.isGame]
            }
        }
        set {
            var prefs = allPrefs
            prefs[info.bundleIdentifier] = newValue
            allPrefs = prefs
        }
    }

    func reset() {
        adaptiveDisplay = info.isGame
        keymapping = info.isGame
        layout = []
    }

    init(_ info: AppInfo, container: AppContainer?) {
        self.info = info
        self.container = container
        createSettingsIfNotExists()
    }
<<<<<<< HEAD

    private func createSettingsIfNotExists() {
        if !fileMgr.fileExists(atPath: AppSettings.settingsUrl.path) || allPrefs[info.bundleIdentifier] == nil {
            dictionary = [AppSettings.keymapping: info.isGame, AppSettings.adaptiveDisplay: info.isGame,
                          AppSettings.refreshRate: 60, AppSettings.sensivity: 50]
        }
    }

    public func export() {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = false
                    openPanel.allowsMultipleSelection = false
                    openPanel.canChooseDirectories = true
                    openPanel.canCreateDirectories = true
                    openPanel.title = "Choose a place to export keymapping to"

                    openPanel.begin { (result) in
                        if result == .OK {
                            do {
                                let selectedPath = openPanel.url!
                                    .appendingPathComponent(self.info.bundleIdentifier)
                                    .appendingPathExtension("playmap")
                                try self.dictionary.store(selectedPath)
                                selectedPath.openInFinder()
                            } catch {
                                openPanel.close()
                                Log.shared.error(error)
                            }
                            openPanel.close()
                        }
                    }
        }

    public func importOf(returnCompletion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playmap")]
        openPanel.title = "Select a valid file ending in .playmap"

        openPanel.begin { (result) in
            if result == .OK {
                do {
                    if let selectedPath = openPanel.url {
                        if let newPrefs = try [String: Any].read(selectedPath) {
                            if !newPrefs.isEmpty {
                                self.dictionary = newPrefs
                                returnCompletion(selectedPath)
                            } else {
                                returnCompletion(nil)
                            }
                        }
                    }
                } catch {
                    returnCompletion(nil)
                    openPanel.close()
                    Log.shared.error(error)
                }
                openPanel.close()
            }
        }
    }

}

extension Dictionary {

    func store(_ toUrl: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: 0)
        try data.write(to: toUrl)
    }

    static func read( _ from: URL) throws -> Dictionary? {
        var format = PropertyListSerialization.PropertyListFormat.xml
        if let data = FileManager.default.contents(atPath: from.path) {
            return try PropertyListSerialization
                .propertyList(from: data,
                              options: .mutableContainersAndLeaves,
                              format: &format) as? Dictionary
        }
        return nil
    }

    static func read( _ from: String) throws -> Dictionary? {
        var format = PropertyListSerialization.PropertyListFormat.xml
        if let data = from.data(using: .utf8) {
            return try PropertyListSerialization
                .propertyList(from: data,
                              options: .mutableContainersAndLeaves,
                              format: &format) as? Dictionary
        }
        return nil
    }

}
