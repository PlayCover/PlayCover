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

extension AppInfo {
    var deviceFamilies: [Int] {
        if let ints = self[ints: "UIDeviceFamily"], !ints.isEmpty {
            return ints
        }
        if let numbers = self[numbers: "UIDeviceFamily"], !numbers.isEmpty {
            return numbers.map(\.intValue)
        }
        return [1]
    }

    var supportsIPad: Bool {
        deviceFamilies.contains(2)
    }

    private static func parseSDKVersion(_ sdkName: String?) -> (major: Int, minor: Int) {
        guard let sdk = sdkName else { return (0, 0) }
        let digits = sdk.drop { !$0.isNumber }
        let parts = digits.split(separator: ".")
        let major = parts.first.flatMap { Int($0) } ?? 0
        let minor = parts.dropFirst().first.flatMap { Int($0) } ?? 0
        return (major, minor)
    }

    var supportsDuoAdaptive: Bool {
        let sdk = Self.parseSDKVersion(self[string: "DTSDKName"])
        return deviceFamilies.contains(1) && (sdk.major > 27 || (sdk.major == 27 && sdk.minor >= 1))
    }

    var requiresFullScreen: Bool {
        let raw = self[bool: "UIRequiresFullScreen"] ?? false
        let ignoredFromStr = (rawStorage["UIRequiresFullScreenIgnoredStartingWithVersion"] as? String)
            ?? (rawStorage["UIRequiresFullScreenIgnoredStartingWithVersion"] as? NSNumber)?.stringValue
        let ignoredFrom = Self.parseSDKVersion(ignoredFromStr)
        let runtimeVer = ProcessInfo.processInfo.operatingSystemVersion
        let ignoresRequiresFullScreen = ignoredFrom.major > 0
            && (runtimeVer.majorVersion > ignoredFrom.major
                || (runtimeVer.majorVersion == ignoredFrom.major && runtimeVer.minorVersion >= ignoredFrom.minor))
        return raw && !ignoresRequiresFullScreen
    }

    private var supportedOrientations: [String] {
        let ipadOrientations = self[strings: "UISupportedInterfaceOrientations~ipad"] ?? []
        let iphoneOrientations = self[strings: "UISupportedInterfaceOrientations~iphone"] ?? []
        let defaultOrientations = self[strings: "UISupportedInterfaceOrientations"] ?? []
        if supportsIPad && !ipadOrientations.isEmpty {
            return ipadOrientations
        }
        return !iphoneOrientations.isEmpty ? iphoneOrientations : defaultOrientations
    }

    var supportsAdaptiveWindowLayout: Bool {
        supportsAdaptiveWindowLayout(forceSDKShift: false)
    }

    func supportsAdaptiveWindowLayout(forceSDKShift: Bool) -> Bool {
        if forceSDKShift {
            return true
        }
        let orientations = supportedOrientations
        let hasPortrait = orientations.contains { $0.contains("Portrait") }
        let hasLandscape = orientations.contains { $0.contains("Landscape") }
        let hasSceneManifest = rawStorage["UIApplicationSceneManifest"] != nil
        return (supportsIPad || supportsDuoAdaptive)
            && !requiresFullScreen
            && ((hasPortrait && hasLandscape) || hasSceneManifest)
    }

    var recommendedAspectRatio: (width: Int, height: Int) {
        let orientations = supportedOrientations
        let hasPortrait = orientations.contains { $0.contains("Portrait") }
        let hasLandscape = orientations.contains { $0.contains("Landscape") }
        if hasLandscape && !hasPortrait {
            return (16, 9)
        }
        if supportsIPad && !deviceFamilies.contains(1) {
            return (3, 4)
        }
        return (9, 16)
    }

    var recommendedLogicalResolution: (width: Int, height: Int) {
        switch recommendedAspectRatio {
        case (16, 9):
            return (1280, 720)
        case (3, 4):
            return (768, 1024)
        default:
            return (414, 736)
        }
    }
}
