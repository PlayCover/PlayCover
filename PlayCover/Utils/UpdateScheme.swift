//
//  UpdateScheme.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 7/6/24.
//

class UpdateScheme {
    public static let versionsFile = PlayTools.playCoverContainer.appendingPathComponent("VERSION")
    public static var currentVersion: String {
        (try? String(contentsOf: UpdateScheme.versionsFile)) ?? "3.1"
    }
    struct Version: Hashable {
        let components: [Int]
        init(_ string: String) {
            var comps = string.split(separator: ".").compactMap { Int($0) }
            while comps.last == 0 && comps.count > 1 {
                comps.removeLast()
            }
            self.components = comps
        }
    }

    struct Migration {
        let fromVersion: String
        let toVersion: String
        let action: () throws -> Void
    }

    private static let migrations: [Version: Migration] = [
        Version("2"): Migration(
            fromVersion: "2",
            toVersion: "3",
            action: updateFromV2ToV3
        ),
        Version("3"): Migration(
            fromVersion: "3",
            toVersion: "3.1",
            action: updateFromV3ToV3p1
        )
    ]

    public static func checkForUpdate() {
        let maxSteps = migrations.count
        var steps = 0

        while steps < maxSteps {
            let currentVer = Version(currentVersion.trimmingCharacters(in: .whitespacesAndNewlines))

            guard let migration = migrations[currentVer] else {
                print("No more migrations needed")
                return
            }

            do {
                print("Migrating \(migration.fromVersion) → \(migration.toVersion)")
                try migration.action()
            } catch {
                Log.shared.error(error)
                return
            }

            steps += 1
        }
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
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        let directoryContents = try FileManager.default
            .contentsOfDirectory(at: Keymapping.keymappingDir, includingPropertiesForKeys: nil, options: [])

        for file in directoryContents where file.pathExtension.contains("plist") {
            let bundleId = file.deletingPathExtension().lastPathComponent
            let appKeymapDir = Keymapping.keymappingDir.appendingPathComponent(bundleId)
            let keymapFileURL = appKeymapDir.appendingPathComponent("default")
                                            .appendingPathExtension("plist")

            try FileManager.default.createDirectory(at: appKeymapDir,
                                                    withIntermediateDirectories: true)

            try FileManager.default.moveItem(at: file, to: keymapFileURL
            )

            do {
                let data = try encoder.encode(KeymapConfig(defaultKm: keymapFileURL, keymapOrder: [keymapFileURL]))
                try data.write(to: appKeymapDir.appendingPathComponent(".config")
                                               .appendingPathExtension("plist"))
            } catch {
                print(error)
            }
        }

        try "3.1".write(to: UpdateScheme.versionsFile, atomically: false, encoding: .utf8)
    }

}
