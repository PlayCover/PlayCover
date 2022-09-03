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
        url.appendingPathComponent(info.executableName)
    }

    public var entitlements: URL {
        Entitlements.playCoverEntitlementsDir.appendingPathComponent("\(info.bundleIdentifier).plist")
    }

    init(appUrl: URL) {
        url = appUrl
        info = AppInfo(contentsOf: url.appendingPathComponent("Info.plist"))
    }
}
