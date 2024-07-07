//
//  UpdateScheme.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 7/6/24.
//

class UpdateScheme {
    public static let versionsFile = PlayTools.playCoverContainer.appendingPathComponent("VERSION")
    public static var currentVersion: String {
        (try? String(contentsOf: UpdateScheme.versionsFile)) ?? "3"
    }

    public static func checkForUpdate() {
        print("checking for updates")

        do {
            switch UpdateScheme.currentVersion {
            case "2":
                print("attempting to update from v2 to v3")
                try updateFromV2ToV3()
            case "3":
                print("attempting to update from v3 to v3.1")
                try updateFromV3ToV3p1()
            default:
                return
            }
        } catch {
            Log.shared.error(error)
        }

        checkForUpdate()
    }

    private static func updateFromV2ToV3() throws {
        try FileManager.default.createDirectory(at: AppsVM.appDirectory, withIntermediateDirectories: true)

        let directoryContents = try FileManager.default
            .contentsOfDirectory(at: PlayTools.playCoverContainer, includingPropertiesForKeys: nil, options: [])

        let subdirs = directoryContents.filter { $0.hasDirectoryPath }

        for sub in subdirs {
            if sub.pathExtension.contains("app") &&
                FileManager.default.fileExists(atPath: sub.appendingPathComponent("Info")
                    .appendingPathExtension("plist")
                    .path) {
                let app = PlayApp(appUrl: sub)
                app.removeAlias()
                try FileManager.default.moveItem(at: app.url,
                                                 to: AppsVM.appDirectory
                    .appendingPathComponent(app.info.bundleIdentifier)
                    .appendingPathExtension("app"))
            }
        }

        try "3".write(to: UpdateScheme.versionsFile, atomically: false, encoding: .utf8)
    }

    private static func updateFromV3ToV3p1() throws {
        let directoryContents = try FileManager.default
            .contentsOfDirectory(at: Keymapping.keymappingDir, includingPropertiesForKeys: nil, options: [])

        for file in directoryContents where file.pathExtension.contains("plist") {
            let bundleId = file.deletingPathExtension().lastPathComponent
            let appKeymapDir = Keymapping.keymappingDir.appendingPathComponent(bundleId)

            try FileManager.default.createDirectory(at: appKeymapDir,
                                                    withIntermediateDirectories: true)

            try FileManager.default.moveItem(at: file,
                                             to: appKeymapDir.appendingPathComponent("default")
                                                             .appendingPathExtension("plist")
            )
        }

        try "3.1".write(to: UpdateScheme.versionsFile, atomically: false, encoding: .utf8)
    }

}
