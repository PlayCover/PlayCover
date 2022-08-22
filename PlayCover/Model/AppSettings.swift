//
//  AppSettings.swift
//  PlayCover
//

import Foundation
import UniformTypeIdentifiers
import AppKit

class AppSettings {
    // TODO: Use per-app files instead of a monolithic file
    public static let settingsUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Preferences/playcover.plist")

    public func sync() {
        notch = NSScreen.hasNotch()
    }

    let info: AppInfo
    var container: AppContainer?

    //
    // Keymapping settings
    //

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

    private static let mouseMapping = "pc.mouseMapping"
    var mouseMapping: Bool {
        get {
            return dictionary[AppSettings.mouseMapping] as? Bool ?? info.isGame
        }
        set {
            var dict = dictionary
            dict[AppSettings.mouseMapping] = newValue
            dictionary = dict
        }
    }

    private static let sensitivity = "pc.sensitivity"
    var sensitivity: Float {
        get {
            return dictionary[AppSettings.sensitivity] as? Float ?? 50
        }
        set {
            var dict = dictionary
            dict[AppSettings.sensitivity] = newValue
            dictionary = dict
        }
    }

    //
    // Graphics settings
    //

    private static let disableTimeout = "pc.disableTimeout"
    var disableTimeout: Bool {
        get {
            dictionary[AppSettings.disableTimeout] as? Bool ?? false
        }
        set {
            var dict = dictionary
            dict[AppSettings.disableTimeout] = newValue
            dictionary = dict
        }
    }

    private static let iosDeviceModel = "pc.iosDeviceModel"
    var iosDeviceModel: String {
        get {
            dictionary[AppSettings.iosDeviceModel] as? String ?? "iPad8,6"
        }
        set {
            var dict = dictionary
            dict[AppSettings.iosDeviceModel] = newValue
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

    private static let windowWidth = "pc.windowWidth"
    var windowWidth: Int {
        get {
            return dictionary[AppSettings.windowWidth] as? Int ?? 1920
        }
        set {
            var dict = dictionary
            dict[AppSettings.windowWidth] = newValue
            dictionary = dict
        }
    }

    private static let windowHeight = "pc.windowHeight"
    var windowHeight: Int {
        get {
            return dictionary[AppSettings.windowHeight] as? Int ?? 1080
        }
        set {
            var dict = dictionary
            dict[AppSettings.windowHeight] = newValue
            dictionary = dict
        }
    }

    private static let resolution = "pc.resolution"
    var resolution: Int {
        get {
            return dictionary[AppSettings.resolution] as? Int ?? 2
        }
        set {
            var dict = dictionary
            dict[AppSettings.resolution] = newValue
            dictionary = dict
        }
    }

    private static let aspectRatio = "pc.aspectRatio"
    var aspectRatio: Int {
        get {
            return dictionary[AppSettings.aspectRatio] as? Int ?? 1
        }
        set {
            var dict = dictionary
            dict[AppSettings.aspectRatio] = newValue
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
                return [AppSettings.keymapping: info.isGame]
            }
        }
        set {
            var prefs = allPrefs
            prefs[info.bundleIdentifier] = newValue
            allPrefs = prefs
        }
    }

    func reset() {
        allPrefs.removeValue(forKey: info.bundleIdentifier)
        createSettingsIfNotExists()
    }

    init(_ info: AppInfo, container: AppContainer?) {
        self.info = info
        self.container = container
        createSettingsIfNotExists()
    }

    private func createSettingsIfNotExists() {
        if !fileMgr.fileExists(atPath: AppSettings.settingsUrl.path) || allPrefs[info.bundleIdentifier] == nil {
            dictionary =
                [AppSettings.keymapping: info.isGame,
                 AppSettings.mouseMapping: info.isGame,
                 AppSettings.sensitivity: 50,
                 AppSettings.disableTimeout: false,
                 AppSettings.iosDeviceModel: "iPad8,6",
                 AppSettings.refreshRate: 60,
                 AppSettings.windowWidth: 1920,
                 AppSettings.windowHeight: 1080,
                 AppSettings.resolution: 2,
                 AppSettings.aspectRatio: 1]
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
