//
//  FileDownloader.swift
//  PlayCover
//
//  Created by 이승윤 on 2023/01/30.
//

import Foundation

class FileDownlaoder: ObservableObject {

    static let shared = FileDownlaoder()

    @Published var progress: Double = 0.0
    @MainActor private var counter = 0
    private(set) var isDownloading = false
    private var size = -1

    @MainActor func updateProgress(increment: Int) {
        counter += increment
        progress = Double(counter) / Double(size)
        progress = progress > 1 ? 1 : progress
    }

    func cancelDownload() {
        isDownloading = false
    }

    @MainActor func clearProgress() {
        progress = 0
        counter = 0
    }

    public func download(url: URL, filePath: URL) async throws {
        isDownloading = true
        let (size, isMultiSupprot) = try await checkFileStatus(url: url)
        self.size = size
        let data: Data
        if isMultiSupprot {
            data = try await multiDownload(url: url, size: size)
        } else {
            data = try await downloadData(url: url, size: size)
        }
        try data.write(to: filePath)
        isDownloading = false
    }

    private func checkFileStatus(url: URL) async throws -> (size: Int, multiDownload: Bool) {
        let (_, response) = try await URLSession.shared.bytes(from: url)
        let responseHeader = (response as? HTTPURLResponse)?.allHeaderFields
        // swiftlint:disable:next force_cast
        guard let size = Int(responseHeader?["Content-Length"] as! String) else { throw PlayCoverError.notValidLink }
        let multiDownload = responseHeader?["Accept-Ranges"] != nil
        return (size, multiDownload)
    }

    private func downloadData(url: URL, size: Int, offset: Int? = nil) async throws -> Data {
        var urlRequest = URLRequest(url: url)
        if let offset = offset {
            urlRequest.addValue("bytes=\(offset)-\(offset + size - 1)", forHTTPHeaderField: "Range")
        }
        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        guard [200, 206].contains((response as? HTTPURLResponse)?.statusCode) else { throw PlayCoverError.notValidLink }

        var downloadingBytes = DownloadingBytes(size: size)
        var bytesIterator = bytes.makeAsyncIterator()

        while isDownloading, !downloadingBytes.isDone {
            while !downloadingBytes.isChunkDone(), let byte = try await bytesIterator.next() {
                downloadingBytes.append(byte)
            }
            // Update progress only when chunk download is done
            Task.detached(priority: .high) {
                await self.updateProgress(increment: DownloaderPreferences.shared.chunkSize)
            }
        }
        if !isDownloading {
          throw CancellationError()
        }
        return downloadingBytes.data
    }

    private func multiDownload(url: URL, size: Int) async throws -> Data {
        let maxConn = DownloaderPreferences.shared.maxConnections
        let parts = (0..<maxConn).map {
            var partSize = Int((Double(size) / Double(maxConn)).rounded(.up))
            let offset = $0 * partSize
            partSize = min(partSize, size - offset)
            return (index: $0, size: partSize, offset: offset)
        }

        return try await withThrowingTaskGroup(of: IndexedData.self) { group in
            for part in parts {
                group.addTask {
                    try await IndexedData(
                        index: part.index,
                        data: self.downloadData(url: url, size: part.size, offset: part.offset))
                }
            }
            var partedData = [IndexedData]()
            for try await data in group {
                partedData.append(data)
            }
            partedData.sort(by: { $0.index < $1.index })
            return partedData.map { $0.data }.reduce(Data(), +)
        }
    }
}

struct IndexedData {
    var index: Int
    var data: Data

    init(index: Int, data: Data) {
        self.index = index
        self.data = data
    }
}

struct DownloadingBytes {
    private var offset = 0
    private var count = 0
    private let size, chunkSize: Int
    private var bytes: [UInt8]

    var data: Data { Data(bytes[0..<offset]) }

    init(size: Int) {
        self.size = size
        self.chunkSize = DownloaderPreferences.shared.chunkSize
        // pre-allocate bytes array in memory
        bytes = [UInt8](repeating: 0, count: size)
    }

    mutating func append(_ byte: UInt8) {
        bytes[offset] = byte
        offset += 1
        count += 1
    }

    mutating func isChunkDone() -> Bool {
        if count > chunkSize {
            count = 0
            return true
        } else { return false }
    }

    var isDone: Bool { offset == size }
}
