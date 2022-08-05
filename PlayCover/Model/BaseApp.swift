//
//  BaseApp.swift
//  PlayCover
//

import Foundation

public class BaseApp {
    /// All mach-o binaries within the app, including the executable itself.
    /// Call resolveValidMachOs to ensure a non-nil value.
    public var validMachOs: [URL]?

    public let info: AppInfo
    public var url: URL

    public var executable: URL {
        return url.appendingPathComponent(info.executableName)
    }

    public var entitlements: URL {
        return Entitlements.playCoverEntitlementsDir.appendingPathComponent("\(info.bundleIdentifier).plist")
    }

    init(appUrl: URL) {
        self.url = appUrl
        self.info = AppInfo(contentsOf: url.appendingPathComponent("Info.plist"))
    }
}
