//
//  AppInfo.swift
//  PlayCover
//

import Foundation

enum LSApplicationCategoryType: String, CaseIterable {
    case business = "public.app-category.business"
    case developerTools = "public.app-category.developer-tools"
    case education = "public.app-category.education"
    case entertainment = "public.app-category.entertainment"
    case finance = "public.app-category.finance"
    case games = "public.app-category.games"
    case graphicsDesign = "public.app-category.graphics-design"
    case healthcareFitness = "public.app-category.healthcare-fitness"
    case lifestyle = "public.app-category.lifestyle"
    case medical = "public.app-category.medical"
    case music = "public.app-category.music"
    case news = "public.app-category.news"
    case photography = "public.app-category.photography"
    case productivity = "public.app-category.productivity"
    case reference = "public.app-category.reference"
    case socialNetworking = "public.app-category.social-networking"
    case sports = "public.app-category.sports"
    case travel = "public.app-category.travel"
    case utilities = "public.app-category.utilities"
    case video = "public.app-category.video"
    case weather = "public.app-category.weather"
    case none = "public.app-category.none" // Note: This is not in an official category type

    var localizedName: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

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

    var applicationCategoryType: LSApplicationCategoryType {
        get {
            LSApplicationCategoryType(
                rawValue: self[string: "LSApplicationCategoryType"] ?? ""
            ) ?? LSApplicationCategoryType.none
        }
        set {
            if newValue == .none {
                rawStorage.removeObject(forKey: "LSApplicationCategoryType")
            } else {
                self[string: "LSApplicationCategoryType"] = newValue.rawValue
            }
            do {
                try write()
            } catch {
                Log.shared.error(error)
            }
        }
    }

    var minimumOSVersion: String {
        get {
            self[string: "MinimumOSVersion"] ?? ""
        }
        set {
            self[string: "MinimumOSVersion"] = newValue
        }
    }

    var bundleName: String {
        if self[string: "CFBundleName"] == nil || self[string: "CFBundleName"] == "" {
            return self[string: "CFBundleDisplayName"] ?? ""
        } else {
            return self[string: "CFBundleName"] ?? ""
        }
    }

    var displayName: String {
        if self[string: "CFBundleDisplayName"] == nil || self[string: "CFBundleDisplayName"] == "" {
            return self[string: "CFBundleName"] ?? ""
        } else {
            return self[string: "CFBundleDisplayName"] ?? ""
        }
    }

    var bundleIdentifier: String {
        self[string: "CFBundleIdentifier"] ?? ""
    }

    var executableName: String {
        self[string: "CFBundleExecutable"] ?? ""
    }

    var bundleVersion: String {
        self[string: "CFBundleShortVersionString"] ?? ""
    }

    var primaryIconName: String {
        if let bundleIconDict = self[dictionary: "CFBundleIcons~ipad"] {
            if let primaryBundleIconDict: [String: Any] = bundleIconDict["CFBundlePrimaryIcon"] as? [String: Any] {
                if let bundleIconFiles = primaryBundleIconDict["CFBundleIconFiles"] as? [String] {
                    let primaryIconName = bundleIconFiles[bundleIconFiles.count - 1]
                    return primaryIconName
                }
            }
        }

        if let bundleIconDict = self[dictionary: "CFBundleIcons"] {
            if let primaryBundleIconDict: [String: Any] = bundleIconDict["CFBundlePrimaryIcon"] as? [String: Any] {
                if let bundleIconFiles = primaryBundleIconDict["CFBundleIconFiles"] as? [String] {
                    let primaryIconName = bundleIconFiles[bundleIconFiles.count - 1]
                    return primaryIconName
                }
            }
        }

        if let bundleIconFiles = self[strings: "CFBundleIconFiles"] {
            let primaryIconName = bundleIconFiles[bundleIconFiles.count - 1]
            return primaryIconName
        }

        return "AppIcon"
    }

    var lsEnvironment: [String: String] {
        get {
            if self[dictionary: "LSEnvironment"] == nil {
                self[dictionary: "LSEnvironment"] = NSMutableDictionary(dictionary: [String: String]())
            }

            return self[dictionary: "LSEnvironment"] as? [String: String] ?? [:]
        }
        set {
            if self[dictionary: "LSEnvironment"] == nil {
                self[dictionary: "LSEnvironment"] = NSMutableDictionary(dictionary: [String: String]())
            }

            if let key = newValue.first?.key, let value = newValue.first?.value {
                self[dictionary: "LSEnvironment"]?[key] = value

                do {
                    try write()
                } catch {
                    Log.shared.error(error)
                }
            }
        }
    }

    func assert(minimumVersion: Double) {
        if let double = Double(minimumOSVersion) {
            if double > 11.0 {
                minimumOSVersion = Int(minimumVersion).description
            }
        }
    }
}
