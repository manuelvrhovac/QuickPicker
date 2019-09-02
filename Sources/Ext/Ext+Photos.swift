// swiftlint:disable all
//
//  Created by Manuel Vrhovac on 06/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos

enum CollectionPosition {
    case first
    case at(index: Int)
    case last
}

extension PHAsset {
    
    var relatedSmartCollectionSubtype: PHAssetCollectionSubtype? {
        if isFavorite {
            return .smartAlbumFavorites
        }
        if mediaType == .video {
            if mediaSubtypes.contains(.videoHighFrameRate) { return .smartAlbumSlomoVideos }
            if mediaSubtypes.contains(.videoTimelapse) { return .smartAlbumTimelapses }
            return .smartAlbumVideos
        } else {
            if representsBurst { return .smartAlbumBursts }
            if mediaSubtypes.contains(.photoPanorama) { return .smartAlbumPanoramas }
            if mediaSubtypes.contains(.photoScreenshot) { return .smartAlbumScreenshots }
            if #available(iOS 10.3, *) {
                if mediaSubtypes.contains(.photoLive) { return .smartAlbumLivePhotos }
            } else {
                return nil
            }
            if #available(iOS 10.2, *) {
                if mediaSubtypes.contains(.photoDepthEffect) { return .smartAlbumDepthEffect }
            } else {
                return nil
            }
            return nil
        }
    }
}

extension PHAssetCollectionSubtype {
    
    /// Order like in the native Photos app on iOS
    var nativePhotosOrder: Int {
        switch self {
        case .smartAlbumRecentlyAdded: return  100
        case .smartAlbumUserLibrary: return  150
        case .smartAlbumFavorites: return  200
        case .smartAlbumVideos: return  300
        case .smartAlbumScreenshots: return  400
        case .smartAlbumSelfPortraits: return  500
        case .smartAlbumPanoramas: return  600
        case .smartAlbumLivePhotos: return 650
        case .smartAlbumDepthEffect: return 670
        case .smartAlbumBursts: return  690
        case .smartAlbumTimelapses: return  720
        case .smartAlbumSlomoVideos: return  800
        case .smartAlbumGeneric: return 950
        case .smartAlbumLongExposures: return 960
        case .smartAlbumAnimated: return 970
        case .smartAlbumAllHidden: return 980
        default: return self.rawValue
        }
        
    }
    
    
    
}

extension IndexSet {
    
    init(until: Int) {
        self = IndexSet.init(integersIn: (0..<until))
    }
}

extension CGSize {
    
    var double: CGSize {
        return .init(width: width*2, height: height*2)
    }
    var half: CGSize {
        return .init(width: width*0.5, height: height*0.5)
    }
}

extension PHImageManager {
    
    func getThumb(for asset: PHAsset?,
                  in collection: PHAssetCollection,
                  size s: CGSize,
                  completion: @escaping (UIImage?) -> ()) {
        
        guard let asset = asset else { return completion(nil) }
        
        var size = s.double
        let maxSize: CGFloat = 100.0
        if collection.assetCollectionSubtype == .albumCloudShared && max(size.width, size.height) > maxSize {
            size = CGSize(width: maxSize, height: maxSize)
        }

        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
        imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        imageRequestOptions.isSynchronous = false
        
        let retinaScale = UIScreen.main.scale
        let retinaSquare = CGSize(width: size.width * retinaScale, height: size.height * retinaScale)
        
        let cropSideLength = min(asset.pixelWidth, asset.pixelHeight)
        let square = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(cropSideLength), height: CGFloat(cropSideLength))
        let cropRect = square.applying(CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight)))
        
        imageRequestOptions.normalizedCropRect = cropRect
        
        self.requestImage(
            for: asset, targetSize: retinaSquare,
            contentMode: PHImageContentMode.aspectFit,
            options: imageRequestOptions,
            resultHandler: { (image: UIImage?, info :[AnyHashable: Any]?) -> Void in
            DispatchQueue.main.async {
                return completion(image)
            }
        })
    }
}
