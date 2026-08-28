//
//  Installer+playPackage.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 12/19/24.
//

extension Installer {

    static func installFromPackage(packageURL: URL, returnCompletion: @escaping (URL?) -> Void) {
        let installPlayTools: Bool

        if ModifierKeyObserver.shared.isOptionKeyPressed || InstallPreferences.shared.showInstallPopup {
            installPlayTools = installPlayToolsPopup()
        } else {
            installPlayTools = InstallPreferences.shared.alwaysInstallPlayTools
        }

        Task(priority: .userInitiated) {
            InstallVM.shared.next(.begin, 0.0, 0.2)

            let tmpDir = PlayPackage.unzipToTmp(playPackage: packageURL)

            do {
                guard let tmpDir = tmpDir else {
                    throw PlayCoverError.noTmpDir
                }

                var appId: String?
                var wasSuccess = true

                InstallVM.shared.next(.unzip, 0.2, 0.2)

                tmpDir.enumerateContents { url, type in
                    wasSuccess = copyPackageToTmp(url: url, type: type, appId: &appId)
                }

                guard let appId = appId, wasSuccess else {
                    throw PlayCoverError.failPlayPackageInstall
                }

                let playAppPath = AppsVM.appDirectory
                    .appendingPathComponent(appId)
                    .appendingPathExtension("app")

                let playApp = PlayApp(appUrl: playAppPath)

                if installPlayTools {
                    InstallVM.shared.next(.unzip, 0.7, 0.9)
                    try PlayTools.injectInIPA(playApp.executable, payload: playApp.url)
                }

                InstallVM.shared.next(.finish, 0.9, 1.0)

                returnCompletion(playAppPath)
            } catch {
                Log.shared.error(error)

                if let tmpDir = tmpDir {
                    FileManager.default.delete(at: tmpDir)
                }

                InstallVM.shared.next(.failed, 0.95, 1.0)

                returnCompletion(nil)
            }
        }
    }

    private static func copyPackageToTmp(url: URL, type: URLResourceValues, appId: inout String?) -> Bool {
        let startTime = InstallVM.shared.progress
        let endTime = (10 * ceil(startTime) + 1) / 10

        do {
            if url.lastPathComponent == PlayPackage.settingsFile {
                try FileManager.default.moveItem(at: url,
                                                 to: AppSettings.appSettingsDir)
            } else if url.lastPathComponent == PlayPackage.entitlementFile {
                try FileManager.default.moveItem(at: url,
                                                 to: Entitlements.playCoverEntitlementsDir)
            } else if url.lastPathComponent == PlayPackage.keymappingFile {
                try FileManager.default.moveItem(at: url,
                                                 to: Keymapping.keymappingDir)
            } else if url.pathExtension == "app" {
                appId = url.deletingPathExtension().lastPathComponent

                try FileManager.default.moveItem(at: url,
                                                 to: AppsVM.appDirectory)
            } else if (type.isDirectory ?? false) && FileManager.default.fileExists(
                atPath: url.appendingPathComponent("Data").absoluteString
            ) {
                try FileManager.default.moveItem(at: url,
                                                 to: AppContainer.containersURL)
            }
        } catch {
            print(error)

            return false
        }

        InstallVM.shared.next(.unzip, startTime, endTime)

        return true
    }

}
