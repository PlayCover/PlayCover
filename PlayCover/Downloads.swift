//
//  Downloads.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation

class Download {

    var url: URL

    var callback: (Float) -> ()

        var progress: Float = 0.0 {
           didSet {
              self.callback(progress)
           }
        }

    var task: URLSessionDownloadTask?

    init(task: URLSessionDownloadTask? , url : URL, callback : @escaping (Float) -> () ) {
        self.task = task
        self.url = url
        self.callback = callback
    }

}

class DownloadManager: NSObject, URLSessionDownloadDelegate, ObservableObject {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard
            let url = downloadTask.originalRequest?.url,
            let download = activeDownloads[url]
            else {
                return
        }
        download.progress = -1.0
            do {
                let downloadedData = try Data(contentsOf: location)

                DispatchQueue.main.async(execute: {

                    let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
                    let destinationPath = documentDirectoryPath.appendingPathComponent("acades.tar.gz")

                    let pdfFileURL = URL(fileURLWithPath: destinationPath)
                    FileManager.default.createFile(atPath: pdfFileURL.path,
                                                   contents: downloadedData,
                                                   attributes: nil)
                    
                })
            } catch {
                print(error.localizedDescription)
            }
    }
    
    var activeDownloads: [URL: Download] = [:]

    lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard
            let url = downloadTask.originalRequest?.url,
            let download = activeDownloads[url]
            else {
                return
        }
        download.progress = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 1.0
    }
    
    func downloadFile(url : URL, progress: @escaping (Float) -> ()){
        let requestURL: URL = url
              let urlRequest: URLRequest = URLRequest(url: requestURL as URL)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let downloadTask = session.downloadTask(with: urlRequest)
        activeDownloads[url] = Download(task: downloadTask, url: url, callback: progress)
        downloadTask.resume()
    }

}


