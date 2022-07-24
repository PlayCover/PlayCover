//
//  PlayApp.swift
//  PlayCover
//

import Foundation
import Cocoa

public class PhysicialApp: BaseApp {

    public let info: AppInfo

    public var url: URL

    public var executable: URL {
        return url.appendingPathComponent(info.executableName)
    }

    public var entitlements: URL {
        return Entitlements.playCoverEntitlementsDir.appendingPathComponent("\(info.bundleIdentifier).plist")
    }

    init(appUrl: URL, type: AppType) {
        self.url = appUrl
        self.info = AppInfo(contentsOf: url.appendingPathComponent("Info.plist"))
        super.init(id: info.bundleIdentifier, type: type)
    }

}
