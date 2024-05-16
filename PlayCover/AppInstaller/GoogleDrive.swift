import Foundation
import SwiftSoup

class RedirectHandler: NSObject, URLSessionTaskDelegate {
    var finalURL = ""
    let dispatchGroup = DispatchGroup() // DispatchGroup
    var completion: (() -> Void)? // completion handler
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // Funzione per effettuare la richiesta HTTP e ottenere il contenuto della pagina
    func fetchGoogleDrivePageContent(url: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil)
            return
        }
        dispatchGroup.enter() // Enter Group
        let task = session.dataTask(with: url) { data, response, error in
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
    
    func extractDownloadLink(from htmlContent: String) -> String? {
        
        do {
            let doc = try SwiftSoup.parse(htmlContent)
            guard let form = try doc.select("form#download-form").first() else {
                return nil
            }
            
            let action = try form.attr("action")
            let id = try form.select("input[name=id]").attr("value")
            let confirm = try form.select("input[name=confirm]").attr("value")
            let uuid = try form.select("input[name=uuid]").attr("value")
            let directDownloadLink = "\(action)?id=\(id)&confirm=\(confirm)&uuid=\(uuid)"
            finalURL = directDownloadLink
            return directDownloadLink
            
        } catch {
            return nil
        }
    }
    
    func convertGoogleDriveLink(_ originalLink: String) -> URL? {
        
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
    
    func getDirectDownloadLink(for googleDriveLink: String, completion: @escaping () -> Void) {
        self.completion = completion
        fetchGoogleDrivePageContent(url: googleDriveLink) { htmlContent in
            guard let htmlContent = htmlContent else {
                return
            }
            if let directLink = self.extractDownloadLink(from: htmlContent) {
                completion()
            } else {
                completion()
            }
        }
    }
    
    func redirectCatch(from url: URL) {
        dispatchGroup.enter() // Entra nel gruppo
        let task = session.dataTask(with: url) { data, response, error in
            defer { self.dispatchGroup.leave() } // Esci dal gruppo al termine della task
            
            if let error = error {
                return
            }
        }
        task.resume()
    }
    
    func scrapeWebsite(from request: URLRequest) {
        dispatchGroup.enter() // Entra nel gruppo
        let task = session.dataTask(with: request) { data, response, error in
            defer { self.dispatchGroup.leave() } // Esci dal gruppo al termine della task
            
            if let error = error {
                return
            }
            if let data = data, let html = String(data: data, encoding: .utf8) {
                let x = self.extractDownloadLink(from: html)
            }
        }
        task.resume()
    }
    
    // Handle redirects manually
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let redirectURL = request.url {
            let k = self.convertGoogleDriveLink(redirectURL.absoluteString)
            if let url = k {
                var newRequest = URLRequest(url: url)
                newRequest.httpMethod = "GET"
                newRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                
                self.scrapeWebsite(from: newRequest)
                completionHandler(nil)
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }
    }
    
    // Funzione per attendere il completamento di tutte le URLSession tasks
    func waitForAllTasksToComplete() {
        dispatchGroup.wait()
    }
}

