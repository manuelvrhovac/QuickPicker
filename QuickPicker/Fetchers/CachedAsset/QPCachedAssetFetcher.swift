//
//  QPAssetFetcher.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 16/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import Photos
import KVFetcher

/// A fetcher initialized with PHFetchResult<PHAsset> object, which is an array of PHAsset objects fetched with Int index. Automatically caches fetched PHAsset objects.
class QPCachedAssetFetcher: KVFetcher_Caching_Protocol {
    
    typealias Key = Int
    typealias Value = PHAsset
    typealias Cacher = KVCacher<Key, Value>
    
    var _queuedClosures: [() -> Void] = []
    var cacher: KVCacher<Int, PHAsset>
    var timeout: TimeInterval?
    var result: PHFetchResult<PHAsset>!
    
    func _executeFetchValue(for key: Key, completion: ((Value?) -> Void)!) {
        guard key < result.count else { return completion?(nil) ?? () }
        completion?(result.object(at: key))
    }
    
    init(phFetchResult result: PHFetchResult<PHAsset>, cacher: Cacher) {
        self.cacher = cacher
        self.result = result
    }
    
}
