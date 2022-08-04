//
//  Entitlements.swift
//  PlayCover
//

import Foundation
import Yams

class Entitlements {

    static var playCoverEntitlementsDir: URL {
        let entFodler = PlayTools.playCoverContainer.appendingPathComponent("Entitlements")
        if !fileMgr.fileExists(atPath: entFodler.path) {
            do {
                try fileMgr.createDirectory(at: entFodler, withIntermediateDirectories: true, attributes: [:])
            } catch {
                Log.shared.error(error)
            }

        }
        return entFodler
    }

    static func dumpEntitlements(exec: URL) throws -> [String: Any] {
        let result = try [String: Any].read(try copyEntitlements(exec: exec))
        return result ?? [:]
    }

    static func areEntitlementsValid(app: PlayApp) throws -> Bool {
        guard let old = try dumpEntitlements(exec: app.executable) as? [String: AnyHashable] else { return false }
        guard let new = try composeEntitlements(app) as? [String: AnyHashable] else { return false }
        return new.hashValue == old.hashValue
    }

    private static func setBaseEntitlements(_ base: inout [String: Any]) {
        base["com.apple.security.assets.movies.read-write"] = true
        base["com.apple.security.assets.music.read-write"] = true
        base["com.apple.security.assets.pictures.read-write"] = true
        base["com.apple.security.device.audio-input"] = true
        base["com.apple.security.network.client"] = true
        base["com.apple.security.network.server"] = true
        base["com.apple.security.device.bluetooth"] = true
        base["com.apple.security.device.camera"] = true
        base["com.apple.security.device.usb"] = true
        base["com.apple.security.files.downloads.read-write"] = true
        base["com.apple.security.files.user-selected.read-write"] = true
        base["com.apple.security.network.client"] = true
        base["com.apple.security.network.server"] = true
        base["com.apple.security.personal-information.addressbook"] = true
        base["com.apple.security.personal-information.calendars"] = true
        base["com.apple.security.personal-information.location"] = true
        base["com.apple.security.print"] = true
    }

    static func composeEntitlements(_ app: PlayApp) throws -> [String: Any] {
        var base = [String: Any]()
		let bundleID = app.info.bundleIdentifier
        if !bundleID.elementsEqual("com.devsisters.ck") {
            base["com.apple.security.app-sandbox"] = true
        }

        setBaseEntitlements(&base)

        if SystemConfig.isPlaySignActive {
            base["com.apple.private.tcc.allow"] = TCC.split(whereSeparator: \.isNewline)
            if let specific = try [String: Any].read(app.entitlements) {
                for key in specific.keys {
                    base[key] = specific[key]
                }
            }
        }

        var sandboxProfile = [String]()

		var rules = try getDefaultRules()
		if let bundleRules = try getBundleRules(bundleID) {
			if !(bundleRules.allow?.isEmpty ?? true) {
				rules.allow = bundleRules.allow
			}
			if !(bundleRules.bypass?.isEmpty ?? true) {
				rules.bypass = bundleRules.bypass
			}
		}

        sandboxProfile.append(contentsOf: PlayRules.buildRules(rules: rules.allow ?? [], bundleID: bundleID))

        if app.settings.bypass {
			for file in PlayRules.buildRules(rules: rules.blacklist ?? [], bundleID: bundleID) {
                sandboxProfile.append(
                    """
                     (deny file* file-read* file-read-metadata file-ioctl (literal "\(file)"))
                    """
                )
            }

			for file in PlayRules.buildRules(rules: rules.whitelist ?? [], bundleID: bundleID) {
                sandboxProfile.append(
                    """
                     (allow file* file-read* file-read-metadata file-ioctl (literal "\(file)"))
                    """
                )
            }

            sandboxProfile.append(contentsOf: PlayRules.buildRules(rules: rules.bypass ?? [], bundleID: bundleID))

        }

        base["com.apple.security.temporary-exception.sbpl"] = sandboxProfile

        return base
    }

    private static func copyEntitlements(exec: URL) throws -> String {
        var entitlements = try excludeEntitlements(exec: exec)
        if !entitlements.contains("DOCTYPE plist PUBLIC") {
            entitlements = Entitlements.entitlements_template
        }
        return entitlements
    }

    private static func excludeEntitlements(exec: URL) throws -> String {
        let from = try PlayTools.fetchEntitlements(exec)
        if let range: Range<String.Index> = from.range(of: "<?xml") {
            return String(from[range.lowerBound...])
        } else {
            return Entitlements.entitlements_template
        }
    }

    private static let TCC =
    """
    kTCCService
    kTCCServiceAll
    kTCCServiceAddressBook
    kTCCServiceCalendar
    kTCCServiceReminders
    kTCCServiceLiverpool
    kTCCServiceUbiquity
    kTCCServiceShareKit
    kTCCServicePhotos
    kTCCServicePhotosAdd
    kTCCServiceMicrophone
    kTCCServiceCamera
    kTCCServiceMediaLibrary
    kTCCServiceSiri
    kTCCServiceAppleEvents
    kTCCServiceAccessibility
    kTCCServicePostEvent
    kTCCServiceLocation
    kTCCServiceSystemPolicyAllFiles
    kTCCServiceSystemPolicySysAdminFiles
    kTCCServiceSystemPolicyDeveloperFile
    kTCCServiceSystemPolicyDocumentsFolder
    """

	public static func getDefaultRules() throws -> PlayRules {
		var path : String
		if FileManager.default.fileExists(atPath: "~/.config/PlayCover/default.yaml") {
			path = "~/.config/PlayCover/default.yaml"
		} else if let bpath = Bundle.main.path(forResource: "default", ofType: "yaml") {
			path = bpath
		} else {
			throw "Default config not found: default.yaml"
		}

		do {
			let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
			let decoder = YAMLDecoder()
			let decoded: PlayRules = try decoder.decode(PlayRules.self, from: data)
			return decoded
		} catch {
			print("failed to get default rules at \(path): \(error)")
			throw "failed to get default rules at \(path): \(error)"
		}
	}

	public static func getBundleRules(_ bundleID: String) throws -> PlayRules? {
		var path : String
		if FileManager.default.fileExists(atPath: "~/.config/PlayCover/\(bundleID).yaml") {
			path = "~/.config/PlayCover/\(bundleID).yaml"
		} else if let bpath = Bundle.main.path(forResource: bundleID, ofType: "yaml") {
			path = bpath
		} else {
			return nil
		}

		do {
			let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
			let decoder = YAMLDecoder()
			let decoded: PlayRules = try decoder.decode(PlayRules.self, from: data)
			return decoded
		} catch {
			print("failed to get bundle rules at \(path): \(error)")
			throw error
		}
	}

    public static func isAppRequireUnsandbox(_ app: BaseApp) -> Bool {
        return unsandboxedApps.contains(app.info.bundleIdentifier)
    }

    private static let unsandboxedApps = ["com.devsisters.ck"]

    static let entitlements_template = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    </dict>
    </plist>
    """
}

public func ==<K, L: Hashable, R: Hashable>(lhs: [K: L], rhs: [K: R] ) -> Bool {
   (lhs as NSDictionary).isEqual(to: rhs)
}
