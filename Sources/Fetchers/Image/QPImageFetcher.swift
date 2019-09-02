//
//  Created by Manuel Vrhovac on 09/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit
import Photos
import KVFetcher

/// A subclass of KVFetcher.Caching.Active, responsible for any loading of fullsize or thumbnail images from user's photo library.
public class QPImageFetcher: KVFetcher<PHAsset, UIImage?>.CustomCaching<QPImageCacher>.Active {
    
    /// The original type has too long of a name!
    public typealias DeliveryMode = PHImageRequestOptionsDeliveryMode
    
    /// Used only in case of full delivery mode.
    public var displaySize: CGSize = .init(width: 800, height: 800)
    
    /// Full or thumbnail
    public var deliveryMode: DeliveryMode = .fastFormat
    
    public override func _executeFetchValue(for key: PHAsset, completion: ValueCompletion!) {
        let imageManager = PHImageManager.default()
        if deliveryMode == .fastFormat {
            imageManager.requestThumbnailImage(for: key, completion: completion)
        } else {
            imageManager.requestFullImage(for: key, targetSize: displaySize, completion: completion)
        }
    }
}


public extension QPImageFetcher {

    /// Caching+Fetching version (no active fetching)
    convenience init(deliveryMode: DeliveryMode, cacher: Cacher) {
        self.init(keys: [], currentIndex: 0, options: .none, cacher: cacher)
        self.deliveryMode = deliveryMode
    }
    
    /// Just fetching version (no cache or active)
    convenience init(deliveryMode: DeliveryMode) {
        self.init(deliveryMode: deliveryMode, cacher: .init(maxCount: 0))
    }
}
