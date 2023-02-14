//
//  URIHandler.swift
//  PlayCover
//
//  Created by Venti on 14/02/2023.
//

import Foundation

enum URLTypes: Int, Equatable {
    case source
    case keymap
    case app
}

enum URLAction: Int, Equatable {
    case add
    case remove
    case update
    case install
    case open
}

class URLObservable: ObservableObject {
    @Published var url: String?
    @Published var type: URLTypes?
    @Published var action: URLAction?

    public static var shared = URLObservable()
}

struct URLHandler {
    public static var shared = URLHandler()

    func processURL(url: URL) {
        guard let urlComponenents = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
            let uriPath = urlComponenents.path,
            let params = urlComponenents.queryItems else {
                // Fall back to old url handler (for files)
                if url.pathExtension == "ipa" {
                    Installer.install(ipaUrl: url, export: false, returnCompletion: { _ in
                    Task { @MainActor in
                        AppsVM.shared.fetchApps()
                        NotifyService.shared.notify(
                            NSLocalizedString("notification.appInstalled", comment: ""),
                            NSLocalizedString("notification.appInstalled.message", comment: "")
                        )
                    }})
                }
                return
            }
        // URI format: playcoverapp://<object>?action=<action>&<param>=<value>
        // Example: playcoverapp://source?action=add&url=https://homebrew.playcover.io

        // Switch case for main uri path
        switch uriPath {
        case "/source":
            processSourceURL(params: params)
        default:
            // Print URL to console and break
            print("Unknown URL: \(url)")
        }
    }

    func processSourceURL(params: [URLQueryItem]) {
        switch params[0].value {
        case "add":
            // Add source
            if let url = params[1].value {
                URLObservable.shared.url = url
                URLObservable.shared.type = .source
                URLObservable.shared.action = .add
            }
        case "remove":
            // Remove source
            if let url = params[1].value {
                URLObservable.shared.url = url
                URLObservable.shared.type = .source
                URLObservable.shared.action = .remove
            }
        case "update":
            // Update source
            if let url = params[1].value {
                URLObservable.shared.url = url
                URLObservable.shared.type = .source
                URLObservable.shared.action = .update
            }
        default:
            // Print params to console and break
            print("Unknown source URL params: \(params)")
        }
    }
}
