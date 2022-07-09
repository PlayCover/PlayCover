import Foundation

let settings = PlaySettings.shared

extension Dictionary {
    
    func store(_ to : URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: 0)
        try data.write(to: to, options: .atomic)
    }
    
    static func read( _ from : URL) throws -> Dictionary? {
        var format = PropertyListSerialization.PropertyListFormat.xml
        if let data = FileManager.default.contents(atPath: from.path) {
            return try PropertyListSerialization
                .propertyList(from: data,
                              options: .mutableContainersAndLeaves,
                              format: &format) as? Dictionary
        }
        return nil
    }
    
}

@objc public final class PlaySettings : NSObject {
    
    private static let fileExtension = "plist"
    
    @objc public static let shared = PlaySettings()
    
    
    private static let gamingmodeKey = "pc.gamingMode"
    
    lazy var gamingMode : Bool = {
        if let key = settings[PlaySettings.gamingmodeKey] as? Bool {
            return key
        }
        return PlaySettings.isGame
    }()
    
    private static let notchKey = "pc.hasNotch"
    
    lazy var notch : Bool = {
        if let key = settings[PlaySettings.notchKey] as? Bool {
            return key
        }
        return false
    }()
    
    private static let layoutKey = "pc.layout"
    
    lazy var layout : Array<Array<CGFloat>> = [] {
        didSet {
            do {
                settings[PlaySettings.layoutKey] = layout
                allPrefs[Bundle.main.bundleIdentifier!] = settings
                try allPrefs.store(PlaySettings.settingsUrl)
            } catch {
                print("failed to save settings: \(error)")
            }
        }
    }
    
    public func setupLayout() {
        layout = settings[PlaySettings.layoutKey] as? Array<Array<CGFloat>> ?? []
    }
    
    private static let adaptiveDisplayKey = "pc.adaptiveDisplay"
    @objc public var adaptiveDisplay : Bool {
        if let key = settings[PlaySettings.adaptiveDisplayKey] as? Bool {
            return key
        }
        return PlaySettings.isGame
    }
    
    private static let keymappingKey = "pc.keymapping"
    @objc public var keymapping : Bool {
        if let key = settings[PlaySettings.keymappingKey] as? Bool {
            return key
        }
        return PlaySettings.isGame
    }
    
    private static let refreshRateKey = "pc.refreshRate"
    @objc lazy public var refreshRate : Int = {
        if let key = settings[PlaySettings.refreshRateKey] as? Int {
            return key
        }
        return 60
    }()
    
    private static let sensivityKey = "pc.sensivity"
    
    @objc lazy public var sensivity : Float = {
        if let key = settings[PlaySettings.sensivityKey] as? Float {
            return key / 100
        }
        return 0.5
    }()
    
    static var isGame : Bool {
        if let info = Bundle.main.infoDictionary?.description{
            for keyword in PlaySettings.keywords {
                if info.contains(keyword) && !info.contains("xbox"){
                    return true
                }
            }
        }
        return false
    }
    
    lazy var settings : [String: Any] = {
        if let prefs = allPrefs[Bundle.main.bundleIdentifier!] as? [String : Any] {
            return prefs
        }
        return [PlaySettings.adaptiveDisplayKey : PlaySettings.isGame, PlaySettings.keymappingKey : PlaySettings.isGame]
    }()
    
    lazy var allPrefs : [String : Any] = {
        do {
            if let all = try Dictionary<String, Any>.read(PlaySettings.settingsUrl) {
                return all
            }
        } catch {
            print("failed to load settings: \(error)")
        }
        return [:]
    }()
    
    public func clearLegacy() {
        UserDefaults.standard.removeObject(forKey: "layout")
        UserDefaults.standard.removeObject(forKey: "pclayout")
        UserDefaults.standard.removeObject(forKey: PlaySettings.sensivityKey)
        UserDefaults.standard.removeObject(forKey: PlaySettings.refreshRateKey)
        UserDefaults.standard.removeObject(forKey: PlaySettings.keymappingKey)
        UserDefaults.standard.removeObject(forKey: PlaySettings.adaptiveDisplayKey)
    }
    
    public static let settingsUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Preferences/playcover.plist")
    
    private static var keywords = ["game", "unity", "metal", "netflix", "opengl", "minecraft", "mihoyo", "disney"];
    
}
