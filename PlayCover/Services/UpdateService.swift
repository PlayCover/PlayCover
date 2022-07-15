//
//  UpdateService.swift
//  PlayCover
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
                .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

class UpdateService : ObservableObject {

    static let shared = UpdateService()

    static let baseUrl = "https://github.com/PlayCover/PlayCover/releases/download/$/PlayCover_$.dmg"

    @Published var updateLink : String = ""
    @Published var updateVersion: String = ""
    @Published var updateChangelog: String = ""

    func checkUpdate() {
        if let url = URL(string: "https://api.github.com/repos/PlayCover/PlayCover/releases") {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in 
                if let error = error { return }

                if let data = data {
                    let decoder = JSONDecoder()
                    let releases: [GithubRelease] = decoder.decode([GithubRelease].self, from: data)
                    let release = releases.first(where: { $0.draft == false })

                    if let release = release {
                        let version = release.tag_name
                        if version.compare(Bundle.main.releaseVersionNumber! , options: .numeric) == .orderedDescending{
                            if let asset = release.assets.first {
                                updateLink = asset.browser_download_url
                                updateVersion = version
                                updateChangelog = release.body
                            }
                        }
                    }
                }
            }
        }
    }
}

struct GithubRelease: Codable {
    let tag_name: String
    let prerelease: Bool
    let draft: Bool
    let assets: [GithubAsset]
    let body: String
}

struct GithubAsset: Codable {
    let name: String
    let browser_download_url: String
}
