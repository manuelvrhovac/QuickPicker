//
//  PHAssetTranformer.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 09/10/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher

/// Fetcher that fetches UIImage for specific PHAsset object. Set deliveryMode to thumbnail or full version and displaySize if delivering full version. Accepts PHImageManager inside init. 
public class QPImageFetcher: KVFetcher_Protocol {
    
    public typealias Key = PHAsset
    public typealias Value = UIImage
    
    public var _queuedClosures: [() -> Void] = []
    public var timeout: TimeInterval?
    
    
    /// The original type has too long of a name!
    public typealias DeliveryMode = PHImageRequestOptionsDeliveryMode
    
    /// Used only in case of full delivery mode.
    public var displaySize: CGSize = .init(width: 800, height: 800)
    
    /// Full or thumbnail
    public var deliveryMode: DeliveryMode
    
    /// Can be set to existing image manager. If not, a .default() instance is used.
    public var imageManager: PHImageManager
    
    public init(deliveryMode: DeliveryMode, imageManager: PHImageManager? = nil) {
        self.imageManager = imageManager ?? .default()
        self.deliveryMode = deliveryMode
    }
    
    public func _executeFetchValue(for key: PHAsset, completion: ValueCompletion!) {
        if deliveryMode == .fastFormat {
            imageManager.requestThumbnailImage(for: key, completion: completion)
        } else {
            imageManager.requestFullImage(for: key, targetSize: displaySize, completion: completion)
        }
    }
}


public extension QPImageFetcher {
    
    /// Use '.Active' for active fetching version.
    class Caching: QPImageFetcher, KVFetcher_Caching_Protocol {
        public typealias Cacher = QPImageCacher
        
        public var cacher: Cacher
        
        init(deliveryMode: DeliveryMode, cacher: QPImageCacher) {
            self.cacher = cacher
            super.init(deliveryMode: deliveryMode)
        }
    }
}


public extension QPImageFetcher.Caching {
    
    class Active: Caching, KVFetcher_Caching_Active_Protocol {
        public var keys: () -> [PHAsset]
        public var currentIndex: () -> Int
        public var options: Options
        
        /// A simple element fetcher with cacher that automatically keeps track of already fetched keys and its cached value. Keys: a list of PHAsset objects to be fetched.
        public init(
            deliveryMode: DeliveryMode,
            keys: @escaping () -> [Key],
            currentIndex: @escaping () -> Int,
            options: Options,
            cacher: Cacher
            ) {
            self.keys = keys
            self.currentIndex = currentIndex
            self.options = options
            super.init(deliveryMode: deliveryMode, cacher: cacher)
        }
        
        public static var empty: Active {
            return .init(
                deliveryMode: .fastFormat,
                keys: { return [] },
                currentIndex: { return 0 },
                options: .none,
                cacher: .init(maxCount: 0)
            )
        }
    }
}
