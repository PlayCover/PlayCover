//
//  AppSettings.swift
//  PlayCover
//

import AppKit
import Foundation
import UniformTypeIdentifiers

struct AppSettingsData: Codable {
    var keymapping = true
    var mouseMapping = true
    var sensitivity: Float = 50

    var disableTimeout = false
    var iosDeviceModel = "iPad13,8"
    var windowWidth = 1920
    var windowHeight = 1080
    var resolution = 1
    var aspectRatio = 1
    var notch: Bool = NSScreen.hasNotch()
    var bypass = false
    var discordActivity = DiscordActivity()
    var version = "3.0.0"
    var playChain = false
    var playChainDebugging = false
    var inverseScreenValues = false

    init() {}

    // handle old 2.x settings where PlayChain did not exist yet
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keymapping = try container.decodeIfPresent(Bool.self, forKey: .keymapping) ?? true
        mouseMapping = try container.decodeIfPresent(Bool.self, forKey: .mouseMapping) ?? true
        sensitivity = try container.decodeIfPresent(Float.self, forKey: .sensitivity) ?? 50
        disableTimeout = try container.decodeIfPresent(Bool.self, forKey: .disableTimeout) ?? false
        iosDeviceModel = try container.decodeIfPresent(String.self, forKey: .iosDeviceModel) ?? "iPad13,8"
        windowWidth = try container.decodeIfPresent(Int.self, forKey: .windowWidth) ?? 1920
        windowHeight = try container.decodeIfPresent(Int.self, forKey: .windowHeight) ?? 1080
        resolution = try container.decodeIfPresent(Int.self, forKey: .resolution) ?? 1
        aspectRatio = try container.decodeIfPresent(Int.self, forKey: .aspectRatio) ?? 1
        notch = try container.decodeIfPresent(Bool.self, forKey: .notch) ?? NSScreen.hasNotch()
        bypass = try container.decodeIfPresent(Bool.self, forKey: .bypass) ?? false
        discordActivity = try container.decodeIfPresent(DiscordActivity.self,
                                                        forKey: .discordActivity) ?? DiscordActivity()
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "3.0.0"
        playChain = try container.decodeIfPresent(Bool.self, forKey: .playChain) ?? false
        playChainDebugging = try container.decodeIfPresent(Bool.self, forKey: .playChainDebugging) ?? false
        inverseScreenValues = try container.decodeIfPresent(Bool.self, forKey: .inverseScreenValues) ?? false
    }
}

class AppSettings {
    static var appSettingsDir: URL {
        let settingsFolder =
            PlayTools.playCoverContainer.appendingPathComponent("App Settings")
        if !FileManager.default.fileExists(atPath: settingsFolder.path) {
            do {
                try FileManager.default.createDirectory(at: settingsFolder,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }
        return settingsFolder
    }

    let info: AppInfo
    let settingsUrl: URL
    var metalHudEnabled: Bool = false
    var openWithLLDB: Bool = false
    var openLLDBWithTerminal: Bool = true
    var container: AppContainer?
    var settings: AppSettingsData {
        didSet {
            encode()
        }
    }

    init(_ info: AppInfo, container: AppContainer?) {
        self.info = info
        self.container = container
        settingsUrl = AppSettings.appSettingsDir.appendingPathComponent(info.bundleIdentifier)
                                                .appendingPathExtension("plist")
        settings = AppSettingsData()
        if !decode() {
            encode()
        }
    }

    public func sync() {
        settings.notch = NSScreen.hasNotch()
    }

    public func reset() {
        settings = AppSettingsData()
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(AppSettingsData.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

let notchModels = ["MacBookPro18,3", "MacBookPro18,4", "MacBookPro18,1", "MacBookPro18,2", "Mac14,2"]

extension NSScreen {
    public static func hasNotch() -> Bool {
        if let model = NSScreen.getMacModel() {
            return notchModels.contains(model)
        } else {
            return false
        }
    }

    private static func getMacModel() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
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
