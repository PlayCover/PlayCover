//
//  AppInfo.swift
//  PlayCover
//

import Foundation

public class AppInfo {
    public let url: URL
    fileprivate var rawStorage: NSMutableDictionary

    public init(contentsOf url: URL) {
        do {
            rawStorage = try NSMutableDictionary(contentsOf: url, error: ())
            self.url = url
        } catch {
            Log.shared.error(error)
            rawStorage = NSMutableDictionary()
            self.url = URL(fileURLWithPath: "")
        }
    }

    private init(url: URL, rawStorage: NSMutableDictionary) {
        self.url = url
        self.rawStorage = rawStorage
    }

    public func retargeted(toURL url: URL) -> AppInfo {
        guard let copy = rawStorage.mutableCopy() as? NSMutableDictionary
        else { fatalError("Failed to copy rawStorage") }
        return AppInfo(url: url, rawStorage: copy)
    }

    /// Write an XML-serialized representation of this info to the given URL
    func write(toURL url: URL) throws {
        try rawStorage.write(to: url)
    }

    /// Overwrites the file this AppInfo was loaded from
    func write() throws {
        try write(toURL: url)
    }

    subscript(string index: String) -> String? {
        get {
            rawStorage[index] as? String
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(object index: String) -> NSObject? {
        get {
            rawStorage[index] as? NSObject
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(dictionary index: String) -> NSMutableDictionary? {
        get {
            rawStorage[index] as? NSMutableDictionary
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(strings index: String) -> [String]? {
        get {
            rawStorage[index] as? [String]
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(array index: String) -> NSMutableArray? {
        get {
            rawStorage[index] as? NSMutableArray
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(numbers index: String) -> [NSNumber]? {
        get {
            rawStorage[index] as? [NSNumber]
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(ints index: String) -> [Int]? {
        get {
            rawStorage[index] as? [Int]
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(doubles index: String) -> [Double]? {
        get {
            rawStorage[index] as? [Double]
        }
        set {
            rawStorage[index] = newValue
        }
    }

    subscript(bool index: String) -> Bool? {
        get {
            rawStorage[index] as? Bool
        }
        set {
            rawStorage[index] = newValue
        }
    }

    var minimumOSVersion: String {
        get {
            self[string: "MinimumOSVersion"]!
        }
        set {
            self[string: "MinimumOSVersion"] = newValue
        }
    }

    var bundleName: String {
        if self[string: "CFBundleName"] == nil {
            return self[string: "CFBundleDisplayName"]!
        } else {
            return self[string: "CFBundleName"]!
        }
    }

    var displayName: String {
        if self[string: "CFBundleDisplayName"] == nil {
            return self[string: "CFBundleName"]!
        } else {
            return self[string: "CFBundleDisplayName"]!
        }
    }

    var bundleIdentifier: String {
        self[string: "CFBundleIdentifier"]!
    }

    var executableName: String {
        self[string: "CFBundleExecutable"]!
    }

    var bundleVersion: String {
        self[string: "CFBundleShortVersionString"]!
    }

    var primaryIconName: String {
        guard let bundleIconDict = self[dictionary: "CFBundleIcons~ipad"] else {
            return "AppIcon"
        }
        guard let primaryBundleIconDict: [String: Any] = bundleIconDict["CFBundlePrimaryIcon"] as? [String: Any] else {
            return "AppIcon"
        }
        guard let primaryIconName = primaryBundleIconDict["CFBundleIconName"] as? String else {
            return "AppIcon"
        }
        return primaryIconName
    }

    var supportsTrueScreenSizeOnMac: Bool {
        get {
            self[bool: "UISupportsTrueScreenSizeOnMac"]!
        }
        set {
            self[bool: "UISupportsTrueScreenSizeOnMac"] = newValue
        }
    }

    func assert(minimumVersion: Double) {
        if Double(minimumOSVersion)! > 11.0 {
            minimumOSVersion = Int(minimumVersion).description
        }

        supportsTrueScreenSizeOnMac = true
    }
}
