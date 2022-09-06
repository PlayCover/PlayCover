//
//  AssetsExtractor.swift
//  PlayCover
//
//  Created by 이승윤 on 2022/09/07.
//

import Foundation

struct AssetImage: CustomStringConvertible {
    let name: String
    let namedImages: [CUINamedImage]
    var description: String { name }
}

enum AssetError: Error {
    case fileDoesNotExist
    case catalogInitFail
}

struct AssetsExtractor {
    let catalog: CUICatalog

    var imagesList: [AssetImage] {
        var tmpArray = [AssetImage]()
        for imageName in self.catalog.allImageNames() {
            tmpArray.append(assetImage(from: imageName))
        }
        return tmpArray
    }

    init(appUrl url: URL) throws {
        let assetUrl = url.appendingPathComponent("Assets").appendingPathExtension("car")
        guard FileManager.default.fileExists(atPath: assetUrl.path) else {
            throw AssetError.fileDoesNotExist
        }
        do {
            catalog = try CUICatalog(url: assetUrl)
        } catch {
            throw AssetError.catalogInitFail
        }
    }

    func assetImage(from name: String) -> AssetImage {
        let images = self.catalog.images(withName: name)
        var namedImages = [CUINamedImage]()
        for item in images {
            if let image = item as? CUINamedImage {
                namedImages.append(image)
            }
        }
        return AssetImage(name: name, namedImages: namedImages)
    }

    func extractIcons() -> [NSImage] {
        var images = [NSImage]()
        for assetImage in imagesList where assetImage.name.contains("AppIcon") {
            for namedImage in assetImage.namedImages {
                guard let image = namedImage.asNSImage() else { continue }
                images.append(image)
            }
        }
        return images
    }

}

extension CUINamedImage {
    func asNSImage() -> NSImage? {
        guard let cgImage = self._rendition().unslicedImage()?.takeUnretainedValue() else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
