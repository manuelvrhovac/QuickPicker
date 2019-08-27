//
//  Created by Manuel Vrhovac on 11/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import KVFetcher
import Photos

let bundle: Bundle = .init(for: QuickPickerViewController.self)

extension PHAssetCollectionSubtype {
    
    /// Loads the icon from assets for specific collection subtype.
    var icon: UIImage? {
        let subtype = self
        var rawValue = subtype.rawValue
        if rawValue == 215 || rawValue == 212 || rawValue == 214 {
            rawValue = 200
        }
        let image = UIImage(bundleNamed: "icon-\(rawValue).png")
        return image
    }
}

func imageLiteral(resourceName: String) -> UIImage {
    return UIImage(bundleNamed: resourceName)
}

extension UIImage {
    
    /// Loads image from current bundle. A global variable 'bundle' has to be defined for this to compile successfully.
    convenience init(bundleNamed: String) {
        if UIImage(named: bundleNamed, in: bundle, compatibleWith: nil) != nil {
            self.init(named: bundleNamed, in: bundle, compatibleWith: nil)!
        } else {
            print("Couldn't load image for '\(bundleNamed)'")
            self.init(named: "imageNotFound", in: bundle, compatibleWith: nil)!
        }
    }
}

/// A global function that uses UIImage.init(bundleNamed:)
func loadBundledImage(_ name: String) -> UIImage {
    return .init(bundleNamed: name)
}


extension PHAsset {
    
    static func fetchAndCheckIfAssetExists(_ asset: PHAsset) -> Bool {
        let ids = [asset.localIdentifier]
        let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        return result.count >= 1
    }
    
    static func fetchAndCheckIfAllAssetsExist(_ assets: [PHAsset]) -> Bool {
        let ids = assets.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        return fetchResult.count == assets.count
    }
    
    static func findMissingAssets(in assets: [PHAsset]) -> [PHAsset] {
        let ids = assets.map { $0.localIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        let missing = assets.filter { !fetchResult.contains($0) }
        return missing
    }
    
    var existsInPhotos: Bool {
        return PHAsset.fetchAndCheckIfAssetExists(self)
    }
    
}

extension PHImageManager {
    
    /*
    enum RequestQuality {
        case thumbnail
        case full(_ targetSize: CGSize)
    }
    
    func requestImage(for asset: PHAsset, quality: RequestQuality, completion: ((UIImage?) -> Void)?) {
        switch quality {
        case .thumbnail: requestThumbnailImage(for: asset, completion: completion)
        case .full(let size): requestFullImage(for: asset, targetSize: size, completion: completion)
        }
    }*/
    
    func getThumbnail(for asset: PHAsset) -> UIImage? {
        return Syncer<UIImage>.waitFor(timeout: 10.0, task: { semaphore in
            self.requestThumbnailImage(for: asset, completion: { image in
                semaphore.signal(image ?? UIImage())
            })
        })
    }
    
    func requestThumbnailImage(for asset: PHAsset, completion: ((UIImage?) -> Void)?) {
        smartRequestImage(for: asset, deliveryMode: .fastFormat, completion: completion)
    }
    
    func requestFullImage(for asset: PHAsset, targetSize: CGSize, completion: ((UIImage?) -> Void)?) {
        smartRequestImage(for: asset, targetSize: targetSize, deliveryMode: .highQualityFormat, completion: completion)
    }
    
    /// Shortcut for fetching Full (use network, asynchronous, no resizing) or Fast (forbid network, synchronous, fast resize)
    func smartRequestImage(
        for asset: PHAsset,
        targetSize: CGSize = .zero,
        deliveryMode: PHImageRequestOptionsDeliveryMode,
        completion: ((UIImage?) -> Void)?
        ) {
        var ts: CGSize
        let opt = PHImageRequestOptions()
        if deliveryMode == .highQualityFormat {
            // Get / Download full photo:
            opt.isNetworkAccessAllowed = true
            opt.isSynchronous = false
            opt.resizeMode = PHImageRequestOptionsResizeMode.fast
            opt.deliveryMode = .highQualityFormat
            ts = targetSize
        } else {
            // Get thumbnail:
            opt.isNetworkAccessAllowed = false
            opt.isSynchronous = true
            opt.resizeMode = .fast
            opt.deliveryMode = .fastFormat
            let dim: CGFloat = 200.0
            let ratio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            ts = ratio > 1.0 ?
                .init(width: dim * ratio, height: dim)
                : .init(width: dim, height: dim / ratio)
        }
        delay(deliveryMode == .highQualityFormat ? 0.5 : 0.0) {
            self.requestImage(for: asset,
                              targetSize: ts,
                              contentMode: .aspectFill,
                              options: opt) { image, _ in
                completion?(image)
            }
        }
        
    }
    
}

extension UIColor {
    
    static let darkRed = UIColor(red: 0.745, green: 0.156, blue: 0.0745, alpha: 1)
}


extension PHAsset {
    
    var durationString: String? {
        guard mediaType == .video else { return nil }
        let dur = Int(duration)
        return dur < 3600
            ? String(format: "%02d:%02d", dur / 60, dur % 60)
            : String(format: "%02d:%02d:%02d", dur / 3600, dur / 60, dur % 60)
    }
}


extension PHAssetCollection {
    
    /// Returns estimatedAssetCount (nil if == NSNotFound)
    var countOrNil: Int? {
        guard estimatedAssetCount != NSNotFound else { return nil }
        return estimatedAssetCount
    }
}
