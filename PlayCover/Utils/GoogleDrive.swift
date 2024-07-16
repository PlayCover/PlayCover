//
//  GoogleDrive.swift
//  PlayCover
//
//  Created by Edoardo C. on 16/05/24.
//

import Foundation
import SwiftSoup

class RedirectHandler: NSObject, URLSessionTaskDelegate {
    private var finalURL: URL
    private let dispatchGroup = DispatchGroup() // DispatchGroup
    private var completion: (() -> Void)? // completion handler
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    init(url: URL) {
        self.finalURL = url
        super.init()
        if url.absoluteString.contains("drive.google.com") {
            if let myurl = self.convertGoogleDriveLink(url.absoluteString) {
                self.scrapeWebsite(from: URLRequest(url: myurl))
            }
        } else if url.absoluteString.contains("drive.usercontent.google.com") {
            self.scrapeWebsite(from: URLRequest(url: url))
        } else {
            self.redirectCatch(from: url)
        }
        self.waitForAllTasksToComplete()
    }
    func getFinal() -> URL {
        return finalURL
    }
    private func setFinal(url: URL) {
        self.finalURL = url
    }
    private func fetchGoogleDrivePageContent(url: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil)
            return
        }
        dispatchGroup.enter() // Enter Group
        let task = session.dataTask(with: url) { data, _, error in
            defer { self.dispatchGroup.leave() } // Leave group
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let htmlContent = String(data: data, encoding: .utf8)
            completion(htmlContent)
        }
        task.resume()
    }
    private func extractDownloadLink(from htmlContent: String) {
        do {
            let doc = try SwiftSoup.parse(htmlContent)
            guard let form = try doc.select("form#download-form").first() else {
                return
            }
            let action = try form.attr("action")
            let id = try form.select("input[name=id]").attr("value")
            let confirm = try form.select("input[name=confirm]").attr("value")
            let uuid = try form.select("input[name=uuid]").attr("value")
            let directDownloadLink = "\(action)?id=\(id)&confirm=\(confirm)&uuid=\(uuid)"
            let url = URL(string: directDownloadLink)
            if let url = url {
                setFinal(url: url)
            }
        } catch {
            return
        }
    }
    private func convertGoogleDriveLink(_ originalLink: String) -> URL? {
        guard let fileIdRange = originalLink.range(of: "/file/d/") else {
            return nil
        }
        let startIndex = fileIdRange.upperBound
        guard let endIndex = originalLink[startIndex...].firstIndex(of: "/") else {
            return nil
        }
        let fileId = originalLink[startIndex..<endIndex]
        let newLink = "https://drive.usercontent.google.com/download?id=\(fileId)&export=download&authuser=0"
        return URL(string: newLink)
    }
    private func getDirectDownloadLink(for googleDriveLink: String, completion: @escaping () -> Void) {
        self.completion = completion
        fetchGoogleDrivePageContent(url: googleDriveLink) { htmlContent in
            guard htmlContent != nil else {
                        return
                    }
                    completion()
                }
    }
    private func redirectCatch(from url: URL) {
        dispatchGroup.enter() // Enter group
        let task = session.dataTask(with: url) { _, _, error in
            defer { self.dispatchGroup.leave() } // Exit from the group at end of task
            if error != nil {
                return
            }
        }
        task.resume()
    }
    private func scrapeWebsite(from request: URLRequest) {
        dispatchGroup.enter() // Enter group
        let task = session.dataTask(with: request) { data, _, error in
            defer { self.dispatchGroup.leave() } // Exit from the group at end of task
            if error != nil {
                return
            }
            if let data = data, let html = String(data: data, encoding: .utf8) {
                self.extractDownloadLink(from: html)
            }
        }
        task.resume()
    }
    // Handle redirects manually
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let redirectURL = request.url {
            if let url = self.convertGoogleDriveLink(redirectURL.absoluteString) {
                var newRequest = URLRequest(url: url)
                newRequest.httpMethod = "GET"
                newRequest.setValue("""
                Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)
                Chrome/124.0.0.0 Safari/537.36
                """, forHTTPHeaderField: "User-Agent")
                self.scrapeWebsite(from: newRequest)
                completionHandler(nil)
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }
    }
    // Wait URL Session
    private func waitForAllTasksToComplete() {
        let timeout = DispatchTime.now() + DispatchTimeInterval.seconds(5)
        _ = dispatchGroup.wait(timeout: timeout)
    }
}
