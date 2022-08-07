//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct IPALibraryView: View {
    var body: some View {
        Text("IPA Library")
    }
}

struct IPALibraryView_Previews: PreviewProvider {
    static var previews: some View {
        IPALibraryView()
    }
}

protocol FileDownloadingDelegate: AnyObject {
    func updateDownloadProgressWith(progress: Float)
    func downloadFinished(localFilePath: URL)
    func donwloadFailed(witheError error: Error)
}

class Downloader: NSObject, URLSessionDownloadDelegate {
    private weak var delegate: FileDownloadingDelegate?

    func donwload(from url: URL, delegate: FileDownloadingDelegate) {
        self.delegate = delegate
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: url.absoluteString)
        let session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async {
            self.delegate?.downloadFinished(localFilePath: location)
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.delegate?.updateDownloadProgressWith(
                progress: Float(totalBytesWritten)/Float(totalBytesExpectedToWrite))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let errorReceived = error else { assertionFailure("Failed"); return }
        DispatchQueue.main.async {
            self.delegate?.donwloadFailed(witheError: errorReceived)
        }
    }
}
